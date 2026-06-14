<?php
// ─────────────────────────────────────────────────────────────
// LOCAL SECRETS — copy this file to "config.local.php" (same folder) and put
// your real keys in the copy. config.local.php is gitignored, so your keys
// never get committed. Any key here overrides the matching key in config.php.
// ─────────────────────────────────────────────────────────────
return [
  // Your Stripe TEST secret key — Dashboard → Developers → API keys →
  // "Reveal test key" (starts with sk_test_).
  'stripe_secret' => 'sk_test_REPLACE_ME',

  // Only if your React app runs somewhere other than the default:
  // 'app_url' => 'http://localhost:5173',
];
