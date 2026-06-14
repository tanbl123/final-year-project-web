<?php
// ─────────────────────────────────────────────────────────────
// The ONLY file you edit to move from local XAMPP → cloud MySQL.
// Keep real credentials out of public git in production.
//
// SECRETS: don't put real keys here (this file is committed). Instead create
// backend/config.local.php (gitignored) returning an array that OVERRIDES any
// keys below — e.g. ['stripe_secret' => 'sk_test_...']. See config.local.example.php.
// ─────────────────────────────────────────────────────────────
$config = [
  'db' => [
    'host'    => '127.0.0.1',
    'port'    => '3306',
    'name'    => 'shoear',
    'user'    => 'root',
    'pass'    => '',          // XAMPP default has no password
    'charset' => 'utf8mb4',
  ],
  'jwt_secret' => 'CHANGE_ME_to_a_long_random_string',

  // Stripe Connect (payouts). Keep the secret OUT of git — set it via the
  // STRIPE_SECRET environment variable OR in config.local.php (use a test
  // key: sk_test_...).
  'stripe_secret' => getenv('STRIPE_SECRET') ?: '',

  // Where Stripe sends the supplier back after hosted onboarding.
  'app_url' => getenv('APP_URL') ?: 'http://localhost:5173',
];

// Local, gitignored overrides (real secrets live here on each machine).
$localFile = __DIR__ . '/config.local.php';
if (is_file($localFile)) {
  $local = require $localFile;
  if (is_array($local)) {
    $config = array_replace($config, $local);
  }
}

return $config;
