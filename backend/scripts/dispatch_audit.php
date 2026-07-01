<?php
// Audit in-house deliveries for dispatch correctness. Flags parcels that:
//   * are CROSS-STATE (supplier state != customer state) — should be Standard, not in-house
//   * have an UNKNOWN state (missing structured state → zone check can't be trusted)
//   * are assigned to a courier whose coverage zone does NOT include the delivery state
//
//   php backend/scripts/dispatch_audit.php
//
// Read-only — makes no changes. Use it to see WHY a courier got an out-of-zone order.

require __DIR__ . '/../lib/db.php';
$pdo = getPDO();

$rows = $pdo->query(
  "SELECT d.deliveryId, d.orderId, d.deliveryMethod, d.deliveryStatus,
          o.deliveryState AS custState,
          s.companyName    AS supplier,
          s.operationalState AS supState,
          dp.deliveryPersonnelId AS courierId, u.fullName AS courierName,
          dp.coverageZones, dp.isAvailable
     FROM delivery d
     JOIN `order` o    ON o.orderId = d.orderId
     JOIN supplier s   ON s.supplierId = d.supplierId
     LEFT JOIN delivery_personnel dp ON dp.deliveryPersonnelId = d.deliveryPersonnelId
     LEFT JOIN `user` u ON u.userId = dp.userId
    WHERE d.deliveryMethod = 'InHouse'
    ORDER BY d.orderId"
)->fetchAll();

echo "In-house deliveries: " . count($rows) . "\n";
echo str_repeat('-', 100) . "\n";

$problems = 0;
foreach ($rows as $r) {
  $cust = trim((string) $r['custState']);
  $sup  = trim((string) $r['supState']);
  $zones = array_values(array_filter(array_map('trim', explode(',', (string) $r['coverageZones']))));

  $flags = [];
  if ($cust === '' || $sup === '') {
    $flags[] = 'UNKNOWN-STATE (cust="' . $cust . '", sup="' . $sup . '")';
  } elseif ($cust !== $sup) {
    $flags[] = "CROSS-STATE ($sup → $cust) — should be STANDARD, not in-house";
  }
  if ($r['courierId'] !== null && $cust !== '' && !in_array($cust, $zones, true)) {
    $flags[] = "OUT-OF-ZONE — courier covers [" . implode(', ', $zones) . "] but delivery is to $cust";
  }

  if ($flags) {
    $problems++;
    printf("%-9s %-9s %-11s  %s → %s\n",
      $r['orderId'], $r['deliveryStatus'],
      $r['courierName'] ? $r['courierName'] : '(unassigned)',
      $sup !== '' ? $sup : '?', $cust !== '' ? $cust : '?');
    foreach ($flags as $f) { echo "            ⚠  $f\n"; }
  }
}

echo str_repeat('-', 100) . "\n";
echo $problems === 0
  ? "✅ No dispatch problems found — every in-house parcel is same-state and in the courier's zone.\n"
  : "⚠  $problems in-house parcel(s) flagged above.\n";
