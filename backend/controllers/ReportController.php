<?php
// Sales & commission reporting. Data is aggregated from paid orders:
//   order_item → product_variant → product (→ supplier)
//   joined to a Successful payment.
// Commission is DERIVED from the active rate in the `commission` table
// (a rate config), not stored per order.

// The commission rate (%) currently in effect, or 0.0 if none configured.
function activeCommissionRate(PDO $pdo): float {
  $stmt = $pdo->query(
    "SELECT commissionRateValue FROM commission
      WHERE commissionStatus = 'Active' AND effectiveDate <= NOW()
      ORDER BY effectiveDate DESC LIMIT 1"
  );
  $rate = $stmt->fetchColumn();
  return $rate === false ? 0.0 : (float) $rate;
}

// GET /reports/sales — the signed-in supplier's own sales summary + per-product
// breakdown (paid orders only). Commission is what the platform takes; net is
// what the supplier keeps.
function handleSupplierSalesReport(PDO $pdo, array $auth): void {
  $supplierId = requireSupplierId($pdo, $auth);
  $rate = activeCommissionRate($pdo);

  $stmt = $pdo->prepare(
    "SELECT p.productId, p.productName,
            SUM(oi.orderQuantity) AS units,
            SUM(oi.orderSubtotal) AS gross
       FROM order_item oi
       JOIN `order` o      ON o.orderId = oi.orderId
       JOIN payment pay    ON pay.orderId = o.orderId AND pay.paymentStatus = 'Successful'
       JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
       JOIN product p      ON p.productId = pv.productId
      WHERE p.supplierId = :sid
      GROUP BY p.productId, p.productName
      ORDER BY gross DESC"
  );
  $stmt->execute(['sid' => $supplierId]);
  $rows = $stmt->fetchAll();

  $gross = 0.0; $units = 0;
  $byProduct = [];
  foreach ($rows as $r) {
    $g = (float) $r['gross'];
    $gross += $g;
    $units += (int) $r['units'];
    $byProduct[] = [
      'productId'   => $r['productId'],
      'productName' => $r['productName'],
      'units'       => (int) $r['units'],
      'gross'       => round($g, 2),
    ];
  }
  $commission = round($gross * $rate / 100, 2);

  sendJson(200, true, [
    'commissionRate' => $rate,
    'summary' => [
      'grossSales'  => round($gross, 2),
      'commission'  => $commission,
      'netEarnings' => round($gross - $commission, 2),
      'unitsSold'   => $units,
      'products'    => count($byProduct),
    ],
    'byProduct' => $byProduct,
  ]);
}

// GET /admin/reports/commission — platform commission across all suppliers
// (paid orders only), broken down per supplier.
function handleAdminCommissionReport(PDO $pdo): void {
  $rate = activeCommissionRate($pdo);

  $stmt = $pdo->query(
    "SELECT s.supplierId, s.companyName,
            SUM(oi.orderQuantity) AS units,
            SUM(oi.orderSubtotal) AS gross
       FROM order_item oi
       JOIN `order` o      ON o.orderId = oi.orderId
       JOIN payment pay    ON pay.orderId = o.orderId AND pay.paymentStatus = 'Successful'
       JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
       JOIN product p      ON p.productId = pv.productId
       JOIN supplier s     ON s.supplierId = p.supplierId
      GROUP BY s.supplierId, s.companyName
      ORDER BY gross DESC"
  );
  $rows = $stmt->fetchAll();

  $totalGross = 0.0; $totalCommission = 0.0;
  $bySupplier = [];
  foreach ($rows as $r) {
    $g = (float) $r['gross'];
    $c = round($g * $rate / 100, 2);
    $totalGross += $g;
    $totalCommission += $c;
    $bySupplier[] = [
      'supplierId'  => $r['supplierId'],
      'companyName' => $r['companyName'],
      'units'       => (int) $r['units'],
      'gross'       => round($g, 2),
      'commission'  => $c,
    ];
  }

  sendJson(200, true, [
    'commissionRate' => $rate,
    'summary' => [
      'grossSales'      => round($totalGross, 2),
      'totalCommission' => round($totalCommission, 2),
      'suppliers'       => count($bySupplier),
    ],
    'bySupplier' => $bySupplier,
  ]);
}
