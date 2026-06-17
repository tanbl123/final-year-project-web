<?php
// ─────────────────────────────────────────────────────────────────────────
// Delivery DISPATCH — auto-assign a courier to a paid order.
//
// Design note (for the report): real platforms (DoorDash, Uber, Grab) treat
// dispatch as a SCORING problem — every candidate courier is scored against
// the order and the best one wins. We follow that exact pattern. Today the
// score weights only the courier's current LOAD (fewest in-progress jobs);
// the function is structured so geographic/ETA, vehicle-type and rating terms
// can be added later as extra weighted terms — without changing the callers.
//
// The production extension would also replace this greedy, one-order-at-a-time
// pick with a batched min-cost assignment across many orders and couriers at
// once. That is identified as future work, not implemented here.
// ─────────────────────────────────────────────────────────────────────────

// Delivery states that still count as "in progress" (occupy a courier).
const DELIVERY_ACTIVE_STATES = ['Assigned', 'PickedUp', 'OutForDelivery'];

// Score a single courier candidate. LOWER score = BETTER candidate.
// Only the load term is live today; the commented terms show how a production
// score would extend (the weights would be tuned, and the inputs supplied by
// scoreCouriers()).
function scoreCourier(array $c): float {
  $W_LOAD = 1.0;                       // weight for current workload
  $score  = $W_LOAD * $c['activeLoad'];

  // Future terms (kept here to document the intended extension):
  //   $W_ETA    = 0.5;  $score += $W_ETA    * $c['etaMinutes'];      // proximity/ETA to pickup
  //   $W_RATING = 2.0;  $score += $W_RATING * (5.0 - $c['rating']);  // prefer higher-rated
  //   $W_VEHICLE...                                                  // vehicle suits order size

  return $score;
}

// Rank every Active courier best-first. Each row carries the inputs the score
// is built from, so the admin UI can show *why* a courier was chosen (its load).
function scoreCouriers(PDO $pdo): array {
  $rows = $pdo->query(
    "SELECT dp.deliveryPersonnelId,
            u.fullName,
            u.userId,
            dp.vehicleInfo,
            COUNT(d.deliveryId) AS activeLoad
       FROM delivery_personnel dp
       JOIN `user` u
         ON u.userId = dp.userId AND u.status = 'Active'
       LEFT JOIN delivery d
         ON d.deliveryPersonnelId = dp.deliveryPersonnelId
        AND d.deliveryStatus IN ('Assigned', 'PickedUp', 'OutForDelivery')
      GROUP BY dp.deliveryPersonnelId, u.fullName, u.userId, dp.vehicleInfo"
  )->fetchAll();

  foreach ($rows as &$r) {
    $r['activeLoad'] = (int) $r['activeLoad'];
    $r['score']      = scoreCourier($r);
  }
  unset($r);

  // Best score first; deliveryPersonnelId as a stable tie-breaker so the pick
  // is deterministic when several couriers are equally idle.
  usort($rows, function ($a, $b) {
    return ($a['score'] <=> $b['score'])
        ?: strcmp($a['deliveryPersonnelId'], $b['deliveryPersonnelId']);
  });

  return $rows;
}

// Ensure a delivery row exists for a (paid) order and auto-assign the best
// available courier. If NO courier is available the delivery is left Pending +
// unassigned, which surfaces it in the admin "needs assignment" queue for a
// manual pick. Safe to call more than once: an already-assigned delivery is
// left untouched.
//
// Returns: ['deliveryId', 'deliveryPersonnelId'|null, 'deliveryStatus', 'auto'].
function assignDelivery(PDO $pdo, string $orderId): array {
  // Already have a delivery for this order?
  $stmt = $pdo->prepare(
    "SELECT deliveryId, deliveryPersonnelId, deliveryStatus
       FROM delivery WHERE orderId = :o"
  );
  $stmt->execute(['o' => $orderId]);
  $existing = $stmt->fetch();

  $candidates = scoreCouriers($pdo);
  $best       = $candidates[0] ?? null;     // best-scoring Active courier, or none

  if ($existing) {
    // Only fill in a courier if it's still unassigned; never override a human's
    // manual choice or an in-progress assignment.
    if ($existing['deliveryPersonnelId'] === null && $best) {
      $pdo->prepare(
        "UPDATE delivery
            SET deliveryPersonnelId = :dp, deliveryStatus = 'Assigned'
          WHERE deliveryId = :id"
      )->execute(['dp' => $best['deliveryPersonnelId'], 'id' => $existing['deliveryId']]);

      return [
        'deliveryId'          => $existing['deliveryId'],
        'deliveryPersonnelId' => $best['deliveryPersonnelId'],
        'deliveryStatus'      => 'Assigned',
        'auto'                => true,
      ];
    }
    return [
      'deliveryId'          => $existing['deliveryId'],
      'deliveryPersonnelId' => $existing['deliveryPersonnelId'],
      'deliveryStatus'      => $existing['deliveryStatus'],
      'auto'                => false,
    ];
  }

  $deliveryId = nextId($pdo, 'delivery', 'deliveryId', 'DLV');

  if ($best) {
    $pdo->prepare(
      "INSERT INTO delivery (deliveryId, orderId, deliveryPersonnelId, deliveryStatus)
       VALUES (:id, :o, :dp, 'Assigned')"
    )->execute(['id' => $deliveryId, 'o' => $orderId, 'dp' => $best['deliveryPersonnelId']]);

    return [
      'deliveryId'          => $deliveryId,
      'deliveryPersonnelId' => $best['deliveryPersonnelId'],
      'deliveryStatus'      => 'Assigned',
      'auto'                => true,
    ];
  }

  // No courier available → queue it for the admin to assign by hand.
  $pdo->prepare(
    "INSERT INTO delivery (deliveryId, orderId, deliveryPersonnelId, deliveryStatus)
     VALUES (:id, :o, NULL, 'Pending')"
  )->execute(['id' => $deliveryId, 'o' => $orderId]);

  return [
    'deliveryId'          => $deliveryId,
    'deliveryPersonnelId' => null,
    'deliveryStatus'      => 'Pending',
    'auto'                => false,
  ];
}
