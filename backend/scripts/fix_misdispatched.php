<?php
// Un-assign in-house deliveries that should never have had an in-house courier:
// cross-state parcels, or ones whose state can't be confirmed (missing supplier/
// customer state). Only touches parcels NOT yet picked up (status 'Assigned'),
// resetting them to Pending + unassigned so the admin can route them by hand
// (or they auto-assign correctly once the data is fixed). Delivered / in-progress
// parcels are never touched.
//
//   php backend/scripts/fix_misdispatched.php          # DRY RUN — shows what would change
//   php backend/scripts/fix_misdispatched.php apply      # actually un-assign them
//
// Root cause is usually a supplier with no operational state — fix that too so
// future orders route correctly (Standard for cross-state, in-house for local).

require __DIR__ . '/../lib/db.php';
require __DIR__ . '/../lib/delivery.php';   // recomputeOrderStatus
$pdo = getPDO();

$apply = in_array('apply', array_slice($argv, 1), true);

$rows = $pdo->query(
  "SELECT d.deliveryId, d.orderId, d.deliveryStatus,
          o.deliveryState AS custState, s.operationalState AS supState,
          u.fullName AS courierName
     FROM delivery d
     JOIN `order` o  ON o.orderId = d.orderId
     JOIN supplier s ON s.supplierId = d.supplierId
     LEFT JOIN delivery_personnel dp ON dp.deliveryPersonnelId = d.deliveryPersonnelId
     LEFT JOIN `user` u ON u.userId = dp.userId
    WHERE d.deliveryMethod = 'InHouse'
      AND d.deliveryPersonnelId IS NOT NULL
      AND d.deliveryStatus = 'Assigned'"
)->fetchAll();

$targets = [];
foreach ($rows as $r) {
  $cust = trim((string) $r['custState']);
  $sup  = trim((string) $r['supState']);
  $sameState = $cust !== '' && $sup !== '' && $cust === $sup;
  if (!$sameState) { $targets[] = $r; }   // cross-state OR unknown-state → shouldn't be in-house
}

if (!$targets) {
  echo "✅ Nothing to fix — every assigned in-house parcel is confirmed same-state.\n";
  exit(0);
}

echo ($apply ? "Un-assigning" : "DRY RUN — would un-assign") . " " . count($targets) . " parcel(s):\n";
foreach ($targets as $r) {
  printf("  %-9s  courier=%-14s  %s → %s\n",
    $r['orderId'], $r['courierName'] ?? '?',
    $r['supState'] !== '' ? $r['supState'] : '?',
    $r['custState'] !== '' ? $r['custState'] : '?');
}

if (!$apply) {
  echo "\nRe-run with 'apply' to un-assign them:  php backend/scripts/fix_misdispatched.php apply\n";
  exit(0);
}

$upd = $pdo->prepare(
  "UPDATE delivery SET deliveryPersonnelId = NULL, deliveryStatus = 'Pending' WHERE deliveryId = :id"
);
foreach ($targets as $r) {
  $upd->execute(['id' => $r['deliveryId']]);
  if (function_exists('recomputeOrderStatus')) { recomputeOrderStatus($pdo, (string) $r['orderId']); }
}
echo "\n✅ Done. Those parcels are back to Pending/unassigned in the admin queue.\n";
echo "   Tip: set the operational state on the affected suppliers so future orders route correctly.\n";
