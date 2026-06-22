<?php
// ─────────────────────────────────────────────────────────────────────
// File storage for product images and 3D models.
//
// SWAP SEAM (now wired): storeUploadedFile() uploads to **Firebase Storage**
// when it's configured (config.local.php: 'firebase_service_account' +
// 'firebase_storage_bucket'), returning a public download URL. With Firebase
// unset it falls back to writing under backend/uploads/ and returning a local
// Apache URL (works on XAMPP with no external service). Nothing else in the app
// cares where the file lives; it only stores/serves the returned URL.
// ─────────────────────────────────────────────────────────────────────

// Lazily load (and cache) the merged config so storage can read the Firebase
// keys without every caller having to thread $config through.
function storageConfig(): array {
  static $cfg = null;
  if ($cfg === null) { $cfg = require __DIR__ . '/../config.php'; }
  return $cfg;
}

// Content type for an upload, by extension (best-effort).
function contentTypeForExt(string $ext): string {
  return [
    'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'png' => 'image/png', 'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    'glb' => 'model/gltf-binary', 'gltf' => 'model/gltf+json',
  ][$ext] ?? 'application/octet-stream';
}

// Upload one validated file to Firebase Storage and return a public download
// URL (uses Firebase download tokens, so the bucket need not be world-readable).
// Returns null if Firebase isn't configured; sends a 500 + exits on a real
// upload failure (so a misconfiguration is visible rather than silently local).
function storeToFirebase(string $tmpPath, string $objectPath, string $ext): ?string {
  $cfg    = storageConfig();
  $saPath = firebaseServiceAccountPath($cfg);
  $bucket = $cfg['firebase_storage_bucket'] ?? '';
  if ($saPath === '' || $bucket === '' || !is_file($saPath)) {
    return null;   // not configured → caller falls back to local disk
  }

  $token = googleAccessToken($saPath, 'https://www.googleapis.com/auth/devstorage.read_write');
  if (!$token) {
    sendJson(500, false, null, ['code' => 'STORAGE', 'message' => 'Could not authenticate with Firebase Storage.']);
  }

  $bytes = file_get_contents($tmpPath);
  $url   = 'https://firebasestorage.googleapis.com/v0/b/' . rawurlencode($bucket)
         . '/o?uploadType=media&name=' . rawurlencode($objectPath);

  $ch = curl_init($url);
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_TIMEOUT        => 30,
    CURLOPT_HTTPHEADER     => [
      'Authorization: Bearer ' . $token,
      'Content-Type: ' . contentTypeForExt($ext),
    ],
    CURLOPT_POSTFIELDS     => $bytes,
  ]);
  $res  = curl_exec($ch);
  $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);

  $data = json_decode((string) $res, true);
  if ($code < 200 || $code >= 300 || !is_array($data)) {
    sendJson(500, false, null, ['code' => 'STORAGE', 'message' => 'Firebase upload failed.']);
  }
  // build the public URL with the download token Firebase returns
  $dlToken = $data['downloadTokens'] ?? '';
  return 'https://firebasestorage.googleapis.com/v0/b/' . rawurlencode($bucket)
       . '/o/' . rawurlencode($objectPath) . '?alt=media' . ($dlToken !== '' ? '&token=' . $dlToken : '');
}

// What each kind of upload is allowed to be. Models are validated by
// extension (browsers send .glb as application/octet-stream, so MIME is
// unreliable); images are additionally checked with getimagesize().
const UPLOAD_KINDS = [
  'image' => [
    'dir'      => 'images',
    'exts'     => ['jpg', 'jpeg', 'png', 'webp'],
    'maxBytes' => 5 * 1024 * 1024,   // 5 MB
  ],
  'model' => [
    'dir'      => 'models',
    'exts'     => ['glb', 'gltf'],
    'maxBytes' => 30 * 1024 * 1024,  // 30 MB
  ],
  // business documents (e.g. the SSM registration certificate) submitted at
  // supplier registration. PDF or an image scan.
  'document' => [
    'dir'      => 'documents',
    'exts'     => ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    'maxBytes' => 10 * 1024 * 1024,  // 10 MB
  ],
];

// Public base URL for served upload files. Derived from the request so it
// works whether the host is localhost or something else. /shoear maps to the
// backend/ folder (same mapping the API uses), and Apache serves files under
// backend/uploads/ directly (the front-controller rewrite only covers api/v1).
function publicUploadsBaseUrl(): string {
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
  $host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
  return $scheme . '://' . $host . '/shoear/uploads';
}

// Validate and store one uploaded file. Returns the public URL on success,
// or sends a 400 and exits on any validation failure.
function storeUploadedFile(array $file, string $kind): string {
  if (!isset(UPLOAD_KINDS[$kind])) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Unknown upload kind.']);
  }
  $rules = UPLOAD_KINDS[$kind];

  if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'File upload failed.']);
  }
  if ($file['size'] <= 0 || $file['size'] > $rules['maxBytes']) {
    $mb = $rules['maxBytes'] / (1024 * 1024);
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => "File must be between 1 byte and {$mb} MB."]);
  }

  $ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
  if (!in_array($ext, $rules['exts'], true)) {
    $allowed = implode(', ', $rules['exts']);
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => "Allowed file types: {$allowed}."]);
  }
  if ($kind === 'image' && getimagesize($file['tmp_name']) === false) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'That file is not a valid image.']);
  }

  // Random, collision-proof filename; never trust the client's name.
  $filename = bin2hex(random_bytes(16)) . '.' . $ext;

  // Prefer Firebase Storage when configured (returns null → fall back to local).
  $firebaseUrl = storeToFirebase($file['tmp_name'], $rules['dir'] . '/' . $filename, $ext);
  if ($firebaseUrl !== null) {
    return $firebaseUrl;
  }

  // ── local disk fallback (XAMPP) ──
  $dir = __DIR__ . '/../uploads/' . $rules['dir'];
  if (!is_dir($dir) && !mkdir($dir, 0775, true) && !is_dir($dir)) {
    sendJson(500, false, null, ['code' => 'STORAGE', 'message' => 'Could not prepare upload directory.']);
  }
  $dest = $dir . '/' . $filename;
  if (!move_uploaded_file($file['tmp_name'], $dest)) {
    sendJson(500, false, null, ['code' => 'STORAGE', 'message' => 'Could not save the uploaded file.']);
  }
  return publicUploadsBaseUrl() . '/' . $rules['dir'] . '/' . $filename;
}
