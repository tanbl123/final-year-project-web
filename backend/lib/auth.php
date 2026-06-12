<?php
// Authentication / authorization middleware.

// Verify the JWT from the Authorization header. Returns the payload, or 401s.
function requireAuth(string $secret): array {
  $token = getBearerToken();
  if (!$token) {
    sendJson(401, false, null, ['code' => 'NO_TOKEN', 'message' => 'Missing authentication token.']);
  }
  $payload = jwt_decode($token, $secret);
  if (!$payload) {
    sendJson(401, false, null, ['code' => 'BAD_TOKEN', 'message' => 'Invalid or expired token.']);
  }
  return $payload;   // ['userId' => ..., 'role' => ..., 'exp' => ...]
}

// Ensure the caller is an Admin (or 403).
function requireAdmin(array $auth): void {
  if (($auth['role'] ?? '') !== 'Admin') {
    sendJson(403, false, null, ['code' => 'FORBIDDEN', 'message' => 'Admin access only.']);
  }
}

// Ensure the caller is a Supplier and return their supplierId (or 403).
function requireSupplierId(PDO $pdo, array $auth): string {
  if (($auth['role'] ?? '') !== 'Supplier') {
    sendJson(403, false, null, ['code' => 'FORBIDDEN', 'message' => 'Supplier access only.']);
  }
  $stmt = $pdo->prepare('SELECT supplierId FROM supplier WHERE userId = :userId');
  $stmt->execute(['userId' => $auth['userId']]);
  $row = $stmt->fetch();
  if (!$row) {
    sendJson(403, false, null, ['code' => 'NO_SUPPLIER', 'message' => 'No supplier profile for this user.']);
  }
  return $row['supplierId'];
}
