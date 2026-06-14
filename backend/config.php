<?php
// ─────────────────────────────────────────────────────────────
// The ONLY file you edit to move from local XAMPP → cloud MySQL.
// Keep real credentials out of public git in production.
// ─────────────────────────────────────────────────────────────
return [
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
  // STRIPE_SECRET environment variable (use a test key: sk_test_...).
  'stripe_secret' => getenv('STRIPE_SECRET') ?: '',

  // Where Stripe sends the supplier back after hosted onboarding.
  'app_url' => getenv('APP_URL') ?: 'http://localhost:5173',
];
