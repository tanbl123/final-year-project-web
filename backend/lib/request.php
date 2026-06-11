<?php
// Helpers for reading the incoming request.

// Read and decode the JSON request body into an array (empty array if none).
function getJsonBody(): array {
  $raw = file_get_contents('php://input');
  $data = json_decode($raw, true);
  return is_array($data) ? $data : [];
}

// Extract the token from an "Authorization: Bearer <token>" header, or null.
function getBearerToken(): ?string {
  $headers = function_exists('getallheaders') ? getallheaders() : [];
  $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
  if (preg_match('/Bearer\s+(.+)/i', $auth, $m)) {
    return trim($m[1]);
  }
  return null;
}
