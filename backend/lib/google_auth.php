<?php
// ─────────────────────────────────────────────────────────────────────
// Shared Google service-account OAuth2 helper.
//
// Both Firebase Storage (file uploads) and Firebase Cloud Messaging (push) use
// the SAME service-account key. This exchanges that key for a short-lived
// access token for a given scope (RS256-signed JWT bearer grant), cached in
// process. Returns null if the key is missing/invalid or the exchange fails.
// ─────────────────────────────────────────────────────────────────────

function googleAccessToken(string $saPath, string $scope): ?string {
  static $cache = [];
  $key = $saPath . '|' . $scope;
  if (isset($cache[$key]) && $cache[$key]['exp'] > time() + 60) {
    return $cache[$key]['token'];
  }

  $sa = json_decode((string) @file_get_contents($saPath), true);
  if (!is_array($sa) || empty($sa['client_email']) || empty($sa['private_key'])) {
    return null;
  }

  $b64 = fn($d) => rtrim(strtr(base64_encode($d), '+/', '-_'), '=');
  $now = time();
  $unsigned = $b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])) . '.' . $b64(json_encode([
    'iss'   => $sa['client_email'],
    'scope' => $scope,
    'aud'   => 'https://oauth2.googleapis.com/token',
    'iat'   => $now,
    'exp'   => $now + 3600,
  ]));
  $sig = '';
  if (!openssl_sign($unsigned, $sig, $sa['private_key'], 'sha256')) {
    return null;
  }
  $assertion = $unsigned . '.' . $b64($sig);

  $ch = curl_init('https://oauth2.googleapis.com/token');
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_TIMEOUT        => 10,
    CURLOPT_POSTFIELDS     => http_build_query([
      'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion'  => $assertion,
    ]),
  ]);
  $res = curl_exec($ch);
  curl_close($ch);

  $data = json_decode((string) $res, true);
  if (!isset($data['access_token'])) {
    return null;
  }
  $cache[$key] = ['token' => $data['access_token'], 'exp' => $now + 3600];
  return $data['access_token'];
}

// The configured Firebase service-account JSON path — shared by Storage + FCM.
// Falls back to the older 'fcm_service_account' key for compatibility.
function firebaseServiceAccountPath(array $cfg): string {
  $p = $cfg['firebase_service_account'] ?? ($cfg['fcm_service_account'] ?? '');
  return is_string($p) ? $p : '';
}
