<?php
// Category endpoints. The public list populates the product form's dropdown;
// the admin endpoints let an admin curate the taxonomy (create/rename/delete).

// GET /categories — list all categories.
function handleListCategories(PDO $pdo): void {
  $stmt = $pdo->query('SELECT categoryId AS id, categoryName AS name FROM category ORDER BY categoryName');
  sendJson(200, true, $stmt->fetchAll());
}

// GET /admin/categories — list with how many products use each (for the
// admin management screen, where usage decides if it can be deleted).
function handleAdminListCategories(PDO $pdo): void {
  $stmt = $pdo->query(
    'SELECT c.categoryId AS id, c.categoryName AS name,
            (SELECT COUNT(*) FROM product p WHERE p.categoryId = c.categoryId) AS productCount
       FROM category c
      ORDER BY c.categoryName'
  );
  $rows = $stmt->fetchAll();
  foreach ($rows as &$r) { $r['productCount'] = (int) $r['productCount']; }
  sendJson(200, true, $rows);
}

// Shared name validation + uniqueness check. $excludeId skips one row (rename).
// Sends an error response and exits on failure; returns the clean name on success.
function validateCategoryName(PDO $pdo, $raw, ?string $excludeId = null): string {
  $name = trim($raw ?? '');
  if ($name === '') {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Category name is required.']);
  }
  if (mb_strlen($name) > 80) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Category name is too long (max 80 characters).']);
  }
  $sql = 'SELECT 1 FROM category WHERE categoryName = :n';
  $params = ['n' => $name];
  if ($excludeId !== null) { $sql .= ' AND categoryId <> :id'; $params['id'] = $excludeId; }
  $chk = $pdo->prepare($sql);
  $chk->execute($params);
  if ($chk->fetch()) {
    sendJson(409, false, null, ['code' => 'CONFLICT', 'message' => 'A category with that name already exists.']);
  }
  return $name;
}

// POST /admin/categories — create a category.
function handleCreateCategory(PDO $pdo): void {
  $body = getJsonBody();
  $name = validateCategoryName($pdo, $body['name'] ?? '');

  $id = nextId($pdo, 'category', 'categoryId', 'CAT');
  $pdo->prepare('INSERT INTO category (categoryId, categoryName) VALUES (:id, :n)')
      ->execute(['id' => $id, 'n' => $name]);

  sendJson(201, true, ['id' => $id, 'name' => $name, 'productCount' => 0]);
}

// PUT /admin/categories/{id} — rename a category.
function handleRenameCategory(PDO $pdo, string $id): void {
  $cur = $pdo->prepare('SELECT categoryId FROM category WHERE categoryId = :id');
  $cur->execute(['id' => $id]);
  if (!$cur->fetch()) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'Category not found.']);
  }

  $body = getJsonBody();
  $name = validateCategoryName($pdo, $body['name'] ?? '', $id);

  $pdo->prepare('UPDATE category SET categoryName = :n WHERE categoryId = :id')
      ->execute(['n' => $name, 'id' => $id]);

  sendJson(200, true, ['id' => $id, 'name' => $name]);
}

// DELETE /admin/categories/{id} — delete, but only if no product uses it.
function handleDeleteCategory(PDO $pdo, string $id): void {
  $cur = $pdo->prepare('SELECT categoryId FROM category WHERE categoryId = :id');
  $cur->execute(['id' => $id]);
  if (!$cur->fetch()) {
    sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => 'Category not found.']);
  }

  $used = $pdo->prepare('SELECT COUNT(*) AS n FROM product WHERE categoryId = :id');
  $used->execute(['id' => $id]);
  $count = (int) $used->fetch()['n'];
  if ($count > 0) {
    sendJson(409, false, null, [
      'code' => 'IN_USE',
      'message' => "Cannot delete: {$count} product(s) still use this category.",
    ]);
  }

  $pdo->prepare('DELETE FROM category WHERE categoryId = :id')->execute(['id' => $id]);
  sendJson(200, true, ['id' => $id, 'deleted' => true]);
}
