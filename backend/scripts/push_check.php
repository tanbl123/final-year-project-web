<?php
// Quick check that FCM push is wired up: verifies the service-account key
// authenticates for the Cloud Messaging scope and reports how many device
// tokens are registered. Optionally sends a real test push.
//
//   php backend/scripts/push_check.php          # check only (no push sent)
//   php backend/scripts/push_check.php send      # ALSO send a test push to every registered device
//
// Reads backend/config.php (which merges in backend/config.local.php) and uses
// the SAME 'firebase_service_account' key as Storage — one key does both.

require __DIR__ . '/../lib/google_auth.php';
require __DIR__ . '/../lib/db.php';
require __DIR__ . '/../lib/push.php';   // fcmSend()
$config = require __DIR__ . '/../config.php';

$doSend = in_array('send', array_slice($argv, 1), true);

$sa = firebaseServiceAccountPath($config);
echo "Service account : " . ($sa !== '' ? $sa : '(not set)') . "\n";
echo "  file exists   : " . ($sa !== '' && is_file($sa) ? 'yes' : 'NO') . "\n";

if ($sa === '' || !is_file($sa)) {
  echo "\n=> FCM is NOT configured — pushes are a silent no-op (in-app bell still works).\n";
  echo "   Add 'firebase_service_account' (a real file path) to backend/config.local.php.\n";
  exit(1);
}

$saJson    = json_decode((string) @file_get_contents($sa), true);
$projectId = $saJson['project_id'] ?? '';
echo "Project id      : " . ($projectId !== '' ? $projectId : '(missing from key!)') . "\n\n";

echo "Authenticating with Google (firebase.messaging)… ";
$token = googleAccessToken($sa, 'https://www.googleapis.com/auth/firebase.messaging');
if (!$token || $projectId === '') {
  echo "FAILED.\n=> Check the service-account JSON is valid and PHP's openssl extension is on.\n";
  exit(1);
}
echo "ok\n";

// How many devices can we reach?
$pdo  = getPDO();
$rows = $pdo->query(
  'SELECT dt.token, dt.platform, u.username, u.role
     FROM device_token dt
     LEFT JOIN `user` u ON u.userId = dt.userId
    ORDER BY dt.updatedAt DESC'
)->fetchAll();

echo "Registered device tokens : " . count($rows) . "\n";
foreach ($rows as $r) {
  echo sprintf("  - %-10s %-16s %s…\n",
    $r['platform'] ?? '?', ($r['username'] ?? '(no user)') . ($r['role'] ? " ({$r['role']})" : ''),
    substr((string) $r['token'], 0, 18));
}

if (count($rows) === 0) {
  echo "\n✅ Backend push is configured and authenticates.\n";
  echo "   No devices registered yet — install the app with google-services.json,\n";
  echo "   sign in as a courier, then re-run to see the token appear.\n";
  exit(0);
}

if (!$doSend) {
  echo "\n✅ Backend push is configured, authenticates, and has devices to reach.\n";
  echo "   Re-run with 'send' to fire a real test push:  php backend/scripts/push_check.php send\n";
  exit(0);
}

echo "\nSending a test push to every registered device…\n";
foreach ($rows as $r) {
  fcmSend($token, (string) $projectId, (string) $r['token'],
    'ShoeAR push test ✓', 'If you can see this, FCM push is working.', null);
  echo "  sent → " . substr((string) $r['token'], 0, 18) . "…\n";
}
echo "\n✅ Test push sent. Check the device(s) for the notification.\n";
