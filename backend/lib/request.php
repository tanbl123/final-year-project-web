<?php
// Helpers for reading the incoming request.

// Read and decode the JSON request body into an array (empty array if none).
function getJsonBody(): array {
  $raw = file_get_contents('php://input');
  $data = json_decode($raw, true);
  return is_array($data) ? $data : [];
}

// Extract the token from "Authorization: Bearer <token>", or null.
// Apache can deliver this header in different places, so we check several.
function getBearerToken(): ?string {
  $auth = '';
  if (function_exists('getallheaders')) {
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
  }
  if (!$auth) {
    $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
  }
  if (preg_match('/Bearer\s+(.+)/i', $auth, $m)) {
    return trim($m[1]);
  }
  return null;
}
