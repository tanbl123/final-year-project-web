<?php
// Handles authentication endpoints.

// POST /auth/login  — verify email + password, return a JWT + basic profile.
function handleLogin(PDO $pdo, string $secret): void {
  $body = getJsonBody();
  $email = trim($body['email'] ?? '');
  $password = $body['password'] ?? '';

  if ($email === '' || $password === '') {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Email and password are required.']);
  }

  // look up the user by email (prepared statement → safe from SQL injection)
  $stmt = $pdo->prepare('SELECT userId, password, role, fullName, status FROM `user` WHERE email = :email');
  $stmt->execute(['email' => $email]);
  $user = $stmt->fetch();

  // same message whether the email or password is wrong (don't leak which)
  if (!$user || !password_verify($password, $user['password'])) {
    sendJson(401, false, null, ['code' => 'AUTH', 'message' => 'Invalid email or password.']);
  }

  // only Active accounts may log in (suppliers start as Pending)
  if ($user['status'] !== 'Active') {
    sendJson(403, false, null, ['code' => 'NOT_ACTIVE', 'message' => 'Your account is ' . $user['status'] . '. Please wait for approval.']);
  }

  // issue a token valid for 7 days
  $now = time();
  $token = jwt_encode([
    'userId' => $user['userId'],
    'role'   => $user['role'],
    'iat'    => $now,
    'exp'    => $now + (7 * 24 * 60 * 60),
  ], $secret);

  sendJson(200, true, [
    'token' => $token,
    'user'  => [
      'userId'   => $user['userId'],
      'role'     => $user['role'],
      'fullName' => $user['fullName'],
      'status'   => $user['status'],
    ],
  ]);
}
