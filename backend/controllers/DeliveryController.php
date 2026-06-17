<?php
// Admin delivery dispatch: view deliveries, the unassigned queue, and the
// courier roster (with live load), plus manually (re)assign a courier.
// The auto-assign logic itself lives in lib/delivery.php.

// GET /admin/deliveries — every delivery with its order + customer + courier.
// Filters: ?status=<deliveryStatus>, ?unassigned=1 (Pending + no courier).
// Unassigned/Pending are listed first so the queue is front-and-centre.
function handleListDeliveries(PDO $pdo): void {
  $status     = trim($_GET['status'] ?? '');
  $unassigned = !empty($_GET['unassigned']);

  $allowed = ['Pending', 'Assigned', 'PickedUp', 'OutForDelivery', 'Delivered', 'Failed'];

  $where  = [];
  $params = [];
  if ($status !== '' && in_array($status, $allowed, true)) {
    $where[] = 'd.deliveryStatus = :status';
    $params['status'] = $status;
  }
  if ($unassigned) {
    $where[] = 'd.deliveryPersonnelId IS NULL';
  }

  $sql =
    "SELECT d.deliveryId, d.orderId, d.deliveryStatus, d.deliveryPersonnelId,
            d.deliveryDate, d.estimatedDeliveryTime,
            cu.fullName  AS courierName,
            o.orderDate, o.orderStatus, o.orderTotalAmount, o.orderDeliveryAddress,
            buyer.fullName AS customerName
       FROM delivery d
       JOIN `order` o          ON o.orderId = d.orderId
       JOIN customer c         ON c.customerId = o.customerId
       JOIN `user` buyer       ON buyer.userId = c.userId
       LEFT JOIN delivery_personnel dp ON dp.deliveryPersonnelId = d.deliveryPersonnelId
       LEFT JOIN `user` cu     ON cu.userId = dp.userId";
  if ($where) { $sql .= ' WHERE ' . implode(' AND ', $where); }
  // Queue first (unassigned, then Pending), then most recent orders.
  $sql .=
    " ORDER BY (d.deliveryPersonnelId IS NULL) DESC,
               FIELD(d.deliveryStatus, 'Pending','Assigned','PickedUp','OutForDelivery','Delivered','Failed'),
               o.orderDate DESC";

  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);
  $rows = $stmt->fetchAll();
  foreach ($rows as &$r) { $r['orderTotalAmount'] = (float) $r['orderTotalAmount']; }
  unset($r);

  sendJson(200, true, ['deliveries' => $rows]);
}

// GET /admin/couriers — the Active courier roster, ranked best-first by the
// same scoring function the auto-assigner uses, each with its current load.
// Powers the manual-assign dropdown (admin sees who is least loaded).
function handleListCouriers(PDO $pdo): void {
  $couriers = scoreCouriers($pdo);
  sendJson(200, true, ['couriers' => $couriers]);
}

// POST /admin/deliveries/{deliveryId}/assign — body: { deliveryPersonnelId }.
// Manually assign or reassign a courier. Allowed while the delivery has not yet
// reached a terminal state (Delivered/Failed).
function handleAssignDelivery(PDO $pdo, string $deliveryId): void {
  $body     = getJsonBody();
  $courierId = trim($body['deliveryPersonnelId'] ?? '');
  if ($courierId === '') {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'A courier is required.']);
  }

  $stmt = $pdo->prepare('SELECT deliveryStatus FROM delivery WHERE deliveryId = :id');
  $stmt->execute(['id' => $deliveryId]);
  $del = $stmt->fetch();
  if (!$del) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'Delivery not found.']);
  }
  if (in_array($del['deliveryStatus'], ['Delivered', 'Failed'], true)) {
    sendJson(409, false, null, ['code' => 'CONFLICT', 'message' => 'This delivery is already closed.']);
  }

  // The courier must exist and be an Active delivery person.
  $stmt = $pdo->prepare(
    "SELECT dp.deliveryPersonnelId
       FROM delivery_personnel dp
       JOIN `user` u ON u.userId = dp.userId AND u.status = 'Active'
      WHERE dp.deliveryPersonnelId = :id"
  );
  $stmt->execute(['id' => $courierId]);
  if (!$stmt->fetch()) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Unknown or inactive courier.']);
  }

  // Assigning from the queue moves Pending → Assigned; reassigning an already
  // in-progress delivery keeps its current status (the courier just changes).
  $newStatus = $del['deliveryStatus'] === 'Pending' ? 'Assigned' : $del['deliveryStatus'];
  $pdo->prepare(
    "UPDATE delivery
        SET deliveryPersonnelId = :dp, deliveryStatus = :s
      WHERE deliveryId = :id"
  )->execute(['dp' => $courierId, 's' => $newStatus, 'id' => $deliveryId]);

  sendJson(200, true, [
    'deliveryId'          => $deliveryId,
    'deliveryPersonnelId' => $courierId,
    'deliveryStatus'      => $newStatus,
  ]);
}
