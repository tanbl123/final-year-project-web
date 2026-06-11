<?php
// ─────────────────────────────────────────────────────────────
// Tiny self-contained JWT (HS256). No external library needed.
// A JWT is three base64url parts joined by dots:  header.payload.signature
// The signature is an HMAC-SHA256 of "header.payload" using our secret,
// so the token can't be tampered with without knowing the secret.
// ─────────────────────────────────────────────────────────────

function base64url_encode($data) {
  return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode($data) {
  return base64_decode(strtr($data, '-_', '+/'));
}

// Build a signed token from a payload array.
function jwt_encode(array $payload, string $secret): string {
  $header = ['typ' => 'JWT', 'alg' => 'HS256'];
  $h = base64url_encode(json_encode($header));
  $p = base64url_encode(json_encode($payload));
  $sig = hash_hmac('sha256', "$h.$p", $secret, true);
  $s = base64url_encode($sig);
  return "$h.$p.$s";
}

// Verify a token. Returns the payload array if valid, or null if not.
function jwt_decode(string $token, string $secret): ?array {
  $parts = explode('.', $token);
  if (count($parts) !== 3) return null;
  [$h, $p, $s] = $parts;

  // recompute the signature and compare (timing-safe)
  $expected = base64url_encode(hash_hmac('sha256', "$h.$p", $secret, true));
  if (!hash_equals($expected, $s)) return null;     // tampered / wrong secret

  $payload = json_decode(base64url_decode($p), true);
  if (!is_array($payload)) return null;

  // reject if expired
  if (isset($payload['exp']) && time() > $payload['exp']) return null;

  return $payload;
}
