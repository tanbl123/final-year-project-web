<?php
// Admin-only endpoints. For now: the supplier approval queue.

// GET /admin/suppliers/pending — list supplier accounts awaiting approval.
function handleListPendingSuppliers(PDO $pdo): void {
  $stmt = $pdo->query(
    "SELECT u.userId, s.supplierId, s.companyName, s.companyAddress,
            u.username, u.email, u.phoneNumber, u.created_at
       FROM `user` u
       JOIN supplier s ON s.userId = u.userId
      WHERE u.role = 'Supplier' AND u.status = 'Pending'
      ORDER BY u.created_at ASC"
  );
  sendJson(200, true, ['suppliers' => $stmt->fetchAll()]);
}

// Shared: move a currently-Pending supplier to a new status (Active/Rejected).
function setSupplierStatus(PDO $pdo, string $userId, string $newStatus): void {
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

  $upd = $pdo->prepare("UPDATE `user` SET status = :s WHERE userId = :id");
  $upd->execute(['s' => $newStatus, 'id' => $userId]);

  sendJson(200, true, ['userId' => $userId, 'status' => $newStatus]);
}

// POST /admin/suppliers/{userId}/approve
function handleApproveSupplier(PDO $pdo, string $userId): void {
  setSupplierStatus($pdo, $userId, 'Active');
}

// POST /admin/suppliers/{userId}/reject
function handleRejectSupplier(PDO $pdo, string $userId): void {
  setSupplierStatus($pdo, $userId, 'Rejected');
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
