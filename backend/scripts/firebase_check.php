<?php
// Quick check that Firebase Storage is wired up: verifies the service-account
// path + bucket are configured, authenticates with Google, and does a real
// test upload — printing a public URL you can open in a browser.
//
//   php backend/scripts/firebase_check.php
//
// Reads backend/config.php (which merges in backend/config.local.php).

require __DIR__ . '/../lib/google_auth.php';
$config = require __DIR__ . '/../config.php';

$sa     = $config['firebase_service_account'] ?? '';
$bucket = $config['firebase_storage_bucket'] ?? '';

echo "Service account : " . ($sa !== '' ? $sa : '(not set)') . "\n";
echo "  file exists   : " . ($sa !== '' && is_file($sa) ? 'yes' : 'NO') . "\n";
echo "Storage bucket  : " . ($bucket !== '' ? $bucket : '(not set)') . "\n\n";

if ($sa === '' || !is_file($sa) || $bucket === '') {
  echo "=> Firebase is NOT fully configured — uploads will fall back to LOCAL disk.\n";
  echo "   Add 'firebase_service_account' (a real file path) and 'firebase_storage_bucket'\n";
  echo "   to backend/config.local.php.\n";
  exit(1);
}

echo "Authenticating with Google… ";
$token = googleAccessToken($sa, 'https://www.googleapis.com/auth/devstorage.read_write');
if (!$token) {
  echo "FAILED.\n=> Check the service-account JSON is valid and PHP's openssl extension is on.\n";
  exit(1);
}
echo "ok\n";

// Real test upload — via the Cloud Storage JSON API (IAM-based), exactly like
// storeToFirebase(). multipart so we can attach the Firebase download token.
$objectPath = 'diagnostics/firebase_check.txt';
$bytes      = 'ShoeAR Firebase Storage check — ok';
$dl         = sprintf('%s-%s-%s-%s-%s',
  bin2hex(random_bytes(4)), bin2hex(random_bytes(2)), bin2hex(random_bytes(2)),
  bin2hex(random_bytes(2)), bin2hex(random_bytes(6)));

$boundary = 'shoearbnd' . bin2hex(random_bytes(8));
$meta = json_encode([
  'name'        => $objectPath,
  'contentType' => 'text/plain',
  'metadata'    => ['firebaseStorageDownloadTokens' => $dl],
]);
$multipart = "--{$boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
           . $meta . "\r\n--{$boundary}\r\nContent-Type: text/plain\r\n\r\n"
           . $bytes . "\r\n--{$boundary}--";

$uploadUrl = 'https://storage.googleapis.com/upload/storage/v1/b/' . rawurlencode($bucket) . '/o?uploadType=multipart';

$ch = curl_init($uploadUrl);
curl_setopt_array($ch, [
  CURLOPT_RETURNTRANSFER => true,
  CURLOPT_POST           => true,
  CURLOPT_TIMEOUT        => 30,
  CURLOPT_HTTPHEADER     => ['Authorization: Bearer ' . $token, 'Content-Type: multipart/related; boundary=' . $boundary],
  CURLOPT_POSTFIELDS     => $multipart,
]);
$res  = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err  = curl_error($ch);
curl_close($ch);

echo "Test upload     : HTTP $code\n";
$data = json_decode((string) $res, true);
if ($code < 200 || $code >= 300 || !is_array($data)) {
  echo "=> Upload FAILED: " . ($err !== '' ? $err : $res) . "\n";
  echo "   Common causes: wrong bucket name (.appspot.com vs .firebasestorage.app),\n";
  echo "   or the service account lacks the Storage Admin IAM role.\n";
  exit(1);
}

$publicUrl = 'https://firebasestorage.googleapis.com/v0/b/' . rawurlencode($bucket)
           . '/o/' . rawurlencode($objectPath) . '?alt=media&token=' . $dl;

echo "\n✅ Firebase Storage works! Open this URL in your browser to confirm:\n$publicUrl\n";
