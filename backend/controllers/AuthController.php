<?php
// Handles authentication endpoints.

// POST /auth/register — create a new SUPPLIER account (status Pending,
// awaiting admin approval). Creates a `user` row + a `supplier` row together.
function handleRegister(PDO $pdo): void {
  $body           = getJsonBody();
  $username       = trim($body['username'] ?? '');
  $email          = trim($body['email'] ?? '');
  $phoneNumber    = trim($body['phoneNumber'] ?? '');
  $companyName    = trim($body['companyName'] ?? '');
  $companyAddress = trim($body['companyAddress'] ?? '');
  $password       = $body['password'] ?? '';

  // the supplier's display name IS their company name (no separate contact name)
  $fullName = $companyName;

  // every field is required (all NOT NULL in the schema)
  if ($username === '' || $email === '' || $phoneNumber === ''
      || $companyName === '' || $companyAddress === '') {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'All fields are required.']);
  }
  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Please enter a valid email.']);
  }
  // password policy: 8+ chars with lower, upper, digit and special char
  if (strlen($password) < 8) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Password must be at least 8 characters.']);
  }
  if (!preg_match('/[a-z]/', $password)) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Password must include a lowercase letter.']);
  }
  if (!preg_match('/[A-Z]/', $password)) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Password must include an uppercase letter.']);
  }
  if (!preg_match('/[0-9]/', $password)) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Password must include a number.']);
  }
  if (!preg_match('/[^a-zA-Z0-9]/', $password)) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Password must include a special character.']);
  }

  // friendly duplicate check (the UNIQUE keys also protect us)
  $chk = $pdo->prepare('SELECT email, username FROM `user` WHERE email = :e OR username = :u');
  $chk->execute(['e' => $email, 'u' => $username]);
  foreach ($chk->fetchAll() as $row) {
    if (strcasecmp($row['email'], $email) === 0) {
      sendJson(409, false, null, ['code' => 'DUPLICATE', 'message' => 'That email is already registered.']);
    }
    if (strcasecmp($row['username'], $username) === 0) {
      sendJson(409, false, null, ['code' => 'DUPLICATE', 'message' => 'That username is already taken.']);
    }
  }

  // create user + supplier together (roll back if either fails)
  $pdo->beginTransaction();
  try {
    $userId = nextId($pdo, 'user', 'userId', 'USR');
    $hash   = password_hash($password, PASSWORD_BCRYPT);
    $pdo->prepare(
      'INSERT INTO `user` (userId, username, password, email, fullName, phoneNumber, role, status)
       VALUES (:id, :un, :pw, :em, :fn, :ph, "Supplier", "Pending")'
    )->execute([
      'id' => $userId, 'un' => $username, 'pw' => $hash, 'em' => $email,
      'fn' => $fullName, 'ph' => $phoneNumber,
    ]);

    $supplierId = nextId($pdo, 'supplier', 'supplierId', 'SUP');
    $pdo->prepare(
      'INSERT INTO supplier (supplierId, userId, companyName, companyAddress)
       VALUES (:sid, :uid, :cn, :ca)'
    )->execute([
      'sid' => $supplierId, 'uid' => $userId, 'cn' => $companyName, 'ca' => $companyAddress,
    ]);

    $pdo->commit();
  } catch (Throwable $e) {
    $pdo->rollBack();
    sendJson(500, false, null, ['code' => 'SERVER', 'message' => 'Could not create the account. Please try again.']);
  }

  sendJson(201, true, ['message' => 'Registration submitted. Your account is pending admin approval.']);
}

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
