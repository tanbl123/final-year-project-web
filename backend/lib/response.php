<?php
// Sends the standard response envelope and stops execution.
// Shape: { "success": bool, "data": mixed|null, "error": object|null }
function sendJson($status, $success, $data = null, $error = null) {
  http_response_code($status);
  header('Content-Type: application/json');
  echo json_encode(['success' => $success, 'data' => $data, 'error' => $error]);
  exit;
}
