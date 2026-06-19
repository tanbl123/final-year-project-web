<?php
// Commission rate configuration (Admin web). The platform charges one active
// commission rate at a time; changing it keeps the old rate as history
// (status Inactive) so past changes are auditable. The per-supplier commission
// *report* lives in ReportController.

// GET /admin/commission — the current active rate + the full change history.
function handleGetCommission(PDO $pdo): void {
  $current = $pdo->query(
    "SELECT commissionId, commissionRateValue, effectiveDate, commissionStatus
       FROM commission
      WHERE commissionStatus = 'Active' AND effectiveDate <= NOW()
      ORDER BY effectiveDate DESC
      LIMIT 1"
  )->fetch();
  if ($current) { $current['commissionRateValue'] = (float) $current['commissionRateValue']; }

  $history = $pdo->query(
    "SELECT c.commissionId, c.commissionRateValue, c.effectiveDate, c.commissionStatus,
            u.fullName AS setBy
       FROM commission c
       LEFT JOIN admin a    ON a.adminId = c.adminId
       LEFT JOIN `user` u   ON u.userId = a.userId
      ORDER BY c.effectiveDate DESC, c.commissionId DESC"
  )->fetchAll();
  foreach ($history as &$h) { $h['commissionRateValue'] = (float) $h['commissionRateValue']; }
  unset($h);

  sendJson(200, true, ['current' => $current ?: null, 'history' => $history]);
}

// POST /admin/commission — set a new active rate. Body: { commissionRateValue }.
// Deactivates the previous active rate and inserts the new one (effective now),
// all in one transaction.
function handleSetCommission(PDO $pdo, array $auth): void {
  $body = getJsonBody();
  $rate = $body['commissionRateValue'] ?? null;
  if (!is_numeric($rate) || (float) $rate < 0 || (float) $rate > 100) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Rate must be a number between 0 and 100.']);
  }
  $rate = round((float) $rate, 2);

  // the admin making the change (commission.adminId references admin)
  $stmt = $pdo->prepare('SELECT adminId FROM admin WHERE userId = :uid');
  $stmt->execute(['uid' => $auth['userId']]);
  $adminId = $stmt->fetchColumn();
  if (!$adminId) {
    sendJson(403, false, null, ['code' => 'FORBIDDEN', 'message' => 'No admin profile for this user.']);
  }

  try {
    $pdo->beginTransaction();
    $pdo->exec("UPDATE commission SET commissionStatus = 'Inactive' WHERE commissionStatus = 'Active'");

    $id = nextId($pdo, 'commission', 'commissionId', 'COM');
    $pdo->prepare(
      "INSERT INTO commission (commissionId, adminId, commissionRateValue, effectiveDate, commissionStatus)
       VALUES (:id, :aid, :rate, NOW(), 'Active')"
    )->execute(['id' => $id, 'aid' => $adminId, 'rate' => $rate]);

    $pdo->commit();
  } catch (Throwable $e) {
    if ($pdo->inTransaction()) { $pdo->rollBack(); }
    sendJson(500, false, null, ['code' => 'DB_ERROR', 'message' => 'Could not update the commission rate.']);
  }

  sendJson(201, true, ['commissionId' => $id, 'commissionRateValue' => $rate]);
}
