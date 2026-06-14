<?php
// Admin-only endpoints. For now: the supplier approval queue.

// GET /admin/suppliers/pending — list supplier accounts awaiting approval.
// Includes the business-verification fields + document URL so the admin can
// actually review the application before approving or rejecting it.
function handleListPendingSuppliers(PDO $pdo): void {
  $stmt = $pdo->query(
    "SELECT u.userId, s.supplierId, s.companyName, s.companyAddress,
            s.businessRegNo, s.businessLicenseUrl, s.taxNumber,
            u.username, u.email, u.phoneNumber, u.created_at
       FROM `user` u
       JOIN supplier s ON s.userId = u.userId
      WHERE u.role = 'Supplier' AND u.status = 'Pending'
      ORDER BY u.created_at ASC"
  );
  sendJson(200, true, ['suppliers' => $stmt->fetchAll()]);
}

// Shared: move a currently-Pending supplier to a new status. Optionally records
// a rejection reason (shown to the supplier) — passing null clears any old one.
function setSupplierStatus(PDO $pdo, string $userId, string $newStatus, ?string $reason = null): void {
  $stmt = $pdo->prepare("SELECT status, role FROM `user` WHERE userId = :id");
  $stmt->execute(['id' => $userId]);
  $row = $stmt->fetch();

  if (!$row || $row['role'] !== 'Supplier') {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'Supplier not found.']);
  }
  // guard against double-reviewing (e.g. two admins, or a stale page)
  if ($row['status'] !== 'Pending') {
    sendJson(409, false, null, ['code' => 'CONFLICT', 'message' => 'This account has already been reviewed.']);
  }

  $upd = $pdo->prepare("UPDATE `user` SET status = :s, rejectionReason = :r WHERE userId = :id");
  $upd->execute(['s' => $newStatus, 'r' => $reason, 'id' => $userId]);

  sendJson(200, true, ['userId' => $userId, 'status' => $newStatus]);
}

// POST /admin/suppliers/{userId}/approve — clears any past rejection reason.
function handleApproveSupplier(PDO $pdo, string $userId): void {
  setSupplierStatus($pdo, $userId, 'Active', null);
}

// POST /admin/suppliers/{userId}/reject — body: { reason, terminal? }.
// terminal=true bans the applicant permanently; otherwise they may fix the
// stated reason and resubmit. A reason is required so the supplier knows why.
function handleRejectSupplier(PDO $pdo, string $userId): void {
  $body     = getJsonBody();
  $reason   = trim($body['reason'] ?? '');
  $terminal = !empty($body['terminal']);

  if ($reason === '') {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'A rejection reason is required.']);
  }
  if (mb_strlen($reason) > 255) {
    $reason = mb_substr($reason, 0, 255);
  }
  setSupplierStatus($pdo, $userId, $terminal ? 'Banned' : 'Rejected', $reason);
}

// ── Product approvals ────────────────────────────────────────────────

// GET /admin/products/pending — list products awaiting approval.
function handleListPendingProducts(PDO $pdo): void {
  $stmt = $pdo->query(
    "SELECT p.productId, p.productName, p.productBrand, p.productPrice,
            p.productDescription, c.categoryName, s.companyName, p.created_at
       FROM product p
       JOIN supplier s ON s.supplierId = p.supplierId
       JOIN category c ON c.categoryId = p.categoryId
      WHERE p.productStatus = 'Pending'
      ORDER BY p.created_at ASC"
  );
  $rows = $stmt->fetchAll();
  foreach ($rows as &$r) { $r['productPrice'] = (float) $r['productPrice']; }
  sendJson(200, true, ['products' => $rows]);
}

// Shared: move a currently-Pending product to a new status (Approved/Rejected).
function setProductStatus(PDO $pdo, string $productId, string $newStatus): void {
  $stmt = $pdo->prepare("SELECT productStatus FROM product WHERE productId = :id");
  $stmt->execute(['id' => $productId]);
  $row = $stmt->fetch();

  if (!$row) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'Product not found.']);
  }
  if ($row['productStatus'] !== 'Pending') {
    sendJson(409, false, null, ['code' => 'CONFLICT', 'message' => 'This product has already been reviewed.']);
  }

  $upd = $pdo->prepare("UPDATE product SET productStatus = :s WHERE productId = :id");
  $upd->execute(['s' => $newStatus, 'id' => $productId]);

  sendJson(200, true, ['productId' => $productId, 'status' => $newStatus]);
}

// POST /admin/products/{productId}/approve
function handleApproveProduct(PDO $pdo, string $productId): void {
  setProductStatus($pdo, $productId, 'Approved');
}

// POST /admin/products/{productId}/reject
function handleRejectProduct(PDO $pdo, string $productId): void {
  setProductStatus($pdo, $productId, 'Rejected');
}

// ── User management ──────────────────────────────────────────────────

// GET /admin/users — list/filter all users (?role=, ?status=, ?search=).
function handleListUsers(PDO $pdo): void {
  $role   = $_GET['role']   ?? '';
  $status = $_GET['status'] ?? '';
  $search = trim($_GET['search'] ?? '');

  $allowedRoles    = ['Admin', 'Supplier', 'Customer', 'DeliveryPersonnel'];
  $allowedStatuses = ['Pending', 'Active', 'Rejected', 'Suspended', 'Deleted'];

  $where = [];
  $params = [];
  if ($role !== '' && in_array($role, $allowedRoles, true)) {
    $where[] = 'role = :role'; $params['role'] = $role;
  }
  if ($status !== '' && in_array($status, $allowedStatuses, true)) {
    $where[] = 'status = :status'; $params['status'] = $status;
  }
  if ($search !== '') {
    $where[] = '(fullName LIKE :q OR username LIKE :q OR email LIKE :q)';
    $params['q'] = '%' . $search . '%';
  }

  $sql = 'SELECT userId, username, fullName, email, phoneNumber, role, status, created_at FROM `user`';
  if ($where) { $sql .= ' WHERE ' . implode(' AND ', $where); }
  $sql .= ' ORDER BY created_at DESC';

  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);
  sendJson(200, true, ['users' => $stmt->fetchAll()]);
}

// GET /admin/users/{userId} — one user with their role-specific profile.
function handleGetUser(PDO $pdo, string $userId): void {
  $stmt = $pdo->prepare(
    'SELECT userId, username, fullName, email, phoneNumber, role, status, created_at, updated_at
       FROM `user` WHERE userId = :id'
  );
  $stmt->execute(['id' => $userId]);
  $u = $stmt->fetch();
  if (!$u) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'User not found.']);
  }

  $profile = null;
  if ($u['role'] === 'Supplier') {
    $p = $pdo->prepare('SELECT supplierId, companyName, companyAddress FROM supplier WHERE userId = :id');
  } elseif ($u['role'] === 'Customer') {
    $p = $pdo->prepare('SELECT customerId, shippingAddress FROM customer WHERE userId = :id');
  } elseif ($u['role'] === 'DeliveryPersonnel') {
    $p = $pdo->prepare('SELECT deliveryPersonnelId, vehicleInfo FROM delivery_personnel WHERE userId = :id');
  } else {
    $p = null;
  }
  if ($p) { $p->execute(['id' => $userId]); $profile = $p->fetch() ?: null; }
  $u['profile'] = $profile;

  sendJson(200, true, $u);
}

// PATCH /admin/users/{userId}/status — change a user's status. Body: { status }.
function handleSetUserStatus(PDO $pdo, array $auth, string $userId): void {
  $body   = getJsonBody();
  $status = trim($body['status'] ?? '');
  $allowed = ['Active', 'Suspended', 'Rejected', 'Deleted'];
  if (!in_array($status, $allowed, true)) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Invalid status.']);
  }
  // safety: an admin can't lock themselves out or touch other admins here
  if (($auth['userId'] ?? '') === $userId) {
    sendJson(409, false, null, ['code' => 'SELF', 'message' => 'You cannot change your own account status.']);
  }

  $stmt = $pdo->prepare('SELECT role FROM `user` WHERE userId = :id');
  $stmt->execute(['id' => $userId]);
  $target = $stmt->fetch();
  if (!$target) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'User not found.']);
  }
  if ($target['role'] === 'Admin') {
    sendJson(403, false, null, ['code' => 'FORBIDDEN', 'message' => 'Admin accounts cannot be changed here.']);
  }

  $upd = $pdo->prepare('UPDATE `user` SET status = :s WHERE userId = :id');
  $upd->execute(['s' => $status, 'id' => $userId]);
  sendJson(200, true, ['userId' => $userId, 'status' => $status]);
}
