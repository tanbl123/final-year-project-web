<?php
// Supplier order views. An order can contain items from several suppliers, so
// every query is scoped to the caller: a supplier only ever sees THEIR own line
// items and their own subtotal for an order — never another supplier's.

// GET /supplier/orders  — orders that contain at least one of this supplier's
// products. Optional ?status= filter. Returns one summary row per order with
// the supplier's item count and subtotal (their share only).
function handleListSupplierOrders(PDO $pdo, array $auth): void {
  $supplierId = requireSupplierId($pdo, $auth);
  $status     = trim($_GET['status'] ?? '');
  $allowed    = ['Placed', 'Paid', 'Processing', 'Shipped', 'OutForDelivery', 'Delivered', 'Completed', 'Cancelled'];

  $where  = ['p.supplierId = :sid'];
  $params = ['sid' => $supplierId];
  if ($status !== '' && in_array($status, $allowed, true)) {
    $where[] = 'o.orderStatus = :st';
    $params['st'] = $status;
  }

  $sql =
    "SELECT o.orderId, o.orderDate, o.orderStatus,
            buyer.fullName AS customerName,
            COUNT(oi.orderItemId)  AS itemCount,
            SUM(oi.orderSubtotal)  AS supplierSubtotal,
            (SELECT rf.refundStatus FROM refund rf
              WHERE rf.orderId = o.orderId ORDER BY rf.requestDate DESC LIMIT 1) AS refundStatus
       FROM `order` o
       JOIN order_item oi      ON oi.orderId = o.orderId
       JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
       JOIN product p          ON p.productId = pv.productId
       JOIN customer c         ON c.customerId = o.customerId
       JOIN `user` buyer       ON buyer.userId = c.userId
      WHERE " . implode(' AND ', $where) . "
      GROUP BY o.orderId, o.orderDate, o.orderStatus, buyer.fullName
      ORDER BY o.orderDate DESC";

  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);
  $rows = $stmt->fetchAll();
  foreach ($rows as &$r) {
    $r['itemCount']        = (int) $r['itemCount'];
    $r['supplierSubtotal'] = (float) $r['supplierSubtotal'];
  }
  unset($r);
  sendJson(200, true, ['orders' => $rows]);
}

// GET /supplier/orders/{orderId}  — one order in detail, limited to this
// supplier's items. 404 if the order has none of their products.
function handleGetSupplierOrder(PDO $pdo, array $auth, string $orderId): void {
  $supplierId = requireSupplierId($pdo, $auth);

  // the supplier's line items for this order (price/size from the snapshots)
  $it = $pdo->prepare(
    "SELECT oi.orderItemId, p.productId, p.productName, p.productBrand AS brand,
            oi.orderSize AS size, oi.orderQuantity AS qty,
            oi.orderUnitPrice AS unitPrice, oi.orderSubtotal AS subtotal
       FROM order_item oi
       JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
       JOIN product p          ON p.productId = pv.productId
      WHERE oi.orderId = :oid AND p.supplierId = :sid
      ORDER BY oi.orderItemId"
  );
  $it->execute(['oid' => $orderId, 'sid' => $supplierId]);
  $items = $it->fetchAll();
  if (count($items) === 0) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'Order not found.']);
  }
  foreach ($items as &$x) {
    $x['qty']       = (int) $x['qty'];
    $x['unitPrice'] = (float) $x['unitPrice'];
    $x['subtotal']  = (float) $x['subtotal'];
  }
  unset($x);

  // order header + customer name + payment status. Per PDPA data minimisation,
  // the supplier does NOT receive the customer's delivery address or contact —
  // they don't deliver (delivery personnel do); they only fulfil their items.
  $h = $pdo->prepare(
    "SELECT o.orderId, o.orderDate, o.orderStatus,
            buyer.fullName AS customerName,
            pay.paymentStatus
       FROM `order` o
       JOIN customer c   ON c.customerId = o.customerId
       JOIN `user` buyer ON buyer.userId = c.userId
       LEFT JOIN payment pay ON pay.orderId = o.orderId
      WHERE o.orderId = :oid"
  );
  $h->execute(['oid' => $orderId]);
  $order = $h->fetch();

  $order['items']            = $items;
  $order['itemCount']        = count($items);
  $order['supplierSubtotal'] = array_sum(array_column($items, 'subtotal'));

  // refund requests on this order (per-order, so the supplier sees them here).
  // No customer PII beyond the name already shown above.
  $rf = $pdo->prepare(
    "SELECT refundId, refundReason, refundAmount, refundStatus, requestDate
       FROM refund WHERE orderId = :oid ORDER BY requestDate DESC"
  );
  $rf->execute(['oid' => $orderId]);
  $refunds = $rf->fetchAll();
  foreach ($refunds as &$x) { $x['refundAmount'] = (float) $x['refundAmount']; }
  unset($x);
  $order['refunds'] = $refunds;

  sendJson(200, true, $order);
}

// ── Admin order oversight (sees everything — all suppliers, full detail) ──────

// GET /admin/orders — every order. Filters: ?status= ?search= (order id / customer).
function handleListAdminOrders(PDO $pdo): void {
  $status  = trim($_GET['status'] ?? '');
  $search  = trim($_GET['search'] ?? '');
  $allowed = ['Placed', 'Paid', 'Processing', 'Shipped', 'OutForDelivery', 'Delivered', 'Completed', 'Cancelled'];

  $where  = [];
  $params = [];
  if (in_array($status, $allowed, true)) { $where[] = 'o.orderStatus = :st'; $params['st'] = $status; }
  if ($search !== '') {
    $where[] = '(o.orderId LIKE :q1 OR buyer.fullName LIKE :q2)';
    $params['q1'] = '%' . $search . '%';
    $params['q2'] = '%' . $search . '%';
  }

  $sql =
    "SELECT o.orderId, o.orderDate, o.orderStatus, o.orderTotalAmount,
            buyer.fullName AS customerName,
            (SELECT COUNT(*) FROM order_item oi WHERE oi.orderId = o.orderId) AS itemCount,
            pay.paymentStatus,
            (SELECT d.deliveryStatus FROM delivery d WHERE d.orderId = o.orderId LIMIT 1) AS deliveryStatus
       FROM `order` o
       JOIN customer c   ON c.customerId = o.customerId
       JOIN `user` buyer ON buyer.userId = c.userId
       LEFT JOIN payment pay ON pay.orderId = o.orderId";
  if ($where) { $sql .= ' WHERE ' . implode(' AND ', $where); }
  $sql .= ' ORDER BY o.orderDate DESC';

  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);
  $rows = $stmt->fetchAll();
  foreach ($rows as &$r) {
    $r['orderTotalAmount'] = (float) $r['orderTotalAmount'];
    $r['itemCount']        = (int) $r['itemCount'];
  }
  unset($r);
  sendJson(200, true, ['orders' => $rows]);
}

// GET /admin/orders/{orderId} — full detail: customer, payment, all items
// (every supplier), delivery and refunds. Admins see full info for dispute handling.
function handleGetAdminOrder(PDO $pdo, string $orderId): void {
  $h = $pdo->prepare(
    "SELECT o.orderId, o.orderDate, o.orderStatus, o.orderTotalAmount, o.orderDeliveryAddress,
            buyer.fullName AS customerName, buyer.email AS customerEmail, buyer.phoneNumber AS customerPhone,
            pay.paymentMethod, pay.transactionId, pay.paymentAmount, pay.paymentStatus, pay.paymentDate
       FROM `order` o
       JOIN customer c   ON c.customerId = o.customerId
       JOIN `user` buyer ON buyer.userId = c.userId
       LEFT JOIN payment pay ON pay.orderId = o.orderId
      WHERE o.orderId = :oid"
  );
  $h->execute(['oid' => $orderId]);
  $order = $h->fetch();
  if (!$order) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'Order not found.']);
  }
  $order['orderTotalAmount'] = (float) $order['orderTotalAmount'];
  if ($order['paymentAmount'] !== null) { $order['paymentAmount'] = (float) $order['paymentAmount']; }

  $it = $pdo->prepare(
    "SELECT oi.orderItemId, p.productName, p.productBrand AS brand, s.companyName AS supplierName,
            oi.orderSize AS size, oi.orderQuantity AS qty,
            oi.orderUnitPrice AS unitPrice, oi.orderSubtotal AS subtotal
       FROM order_item oi
       JOIN product_variant pv ON pv.productVariantId = oi.productVariantId
       JOIN product p          ON p.productId = pv.productId
       JOIN supplier s         ON s.supplierId = p.supplierId
      WHERE oi.orderId = :oid
      ORDER BY oi.orderItemId"
  );
  $it->execute(['oid' => $orderId]);
  $items = $it->fetchAll();
  foreach ($items as &$x) {
    $x['qty']       = (int) $x['qty'];
    $x['unitPrice'] = (float) $x['unitPrice'];
    $x['subtotal']  = (float) $x['subtotal'];
  }
  unset($x);
  $order['items'] = $items;

  $dl = $pdo->prepare(
    "SELECT d.deliveryStatus, cu.fullName AS courierName
       FROM delivery d
       LEFT JOIN delivery_personnel dp ON dp.deliveryPersonnelId = d.deliveryPersonnelId
       LEFT JOIN `user` cu ON cu.userId = dp.userId
      WHERE d.orderId = :oid LIMIT 1"
  );
  $dl->execute(['oid' => $orderId]);
  $order['delivery'] = $dl->fetch() ?: null;

  $rf = $pdo->prepare(
    "SELECT refundId, refundReason, refundAmount, refundStatus, requestDate
       FROM refund WHERE orderId = :oid ORDER BY requestDate DESC"
  );
  $rf->execute(['oid' => $orderId]);
  $refunds = $rf->fetchAll();
  foreach ($refunds as &$x) { $x['refundAmount'] = (float) $x['refundAmount']; }
  unset($x);
  $order['refunds'] = $refunds;

  sendJson(200, true, $order);
}
