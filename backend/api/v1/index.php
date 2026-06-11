<?php
require __DIR__ . '/../../lib/response.php';
require __DIR__ . '/../../lib/db.php';

// ── CORS: let the React dev server (port 5173) call us ──
header('Access-Control-Allow-Origin: http://localhost:5173');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

// ── work out the path after /shoear/api/v1 ──
$uri  = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$base = '/shoear/api/v1';
$path = '/' . trim(substr($uri, strlen($base)), '/');

// ── routes ──
if ($path === '/ping') {
  sendJson(200, true, ['message' => 'pong', 'time' => date('c')]);
}

if ($path === '/db-test') {
  $pdo  = getPDO();
  $stmt = $pdo->query('SELECT COUNT(*) AS total FROM product');
  $row  = $stmt->fetch();
  sendJson(200, true, ['productCount' => (int) $row['total']]);
}

sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => "No route for $path"]);
