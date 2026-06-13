<?php
require __DIR__ . '/../../lib/response.php';
require __DIR__ . '/../../lib/db.php';
require __DIR__ . '/../../lib/jwt.php';
require __DIR__ . '/../../lib/request.php';
require __DIR__ . '/../../lib/auth.php';
require __DIR__ . '/../../lib/ids.php';
require __DIR__ . '/../../lib/storage.php';
require __DIR__ . '/../../controllers/AuthController.php';
require __DIR__ . '/../../controllers/AdminController.php';
require __DIR__ . '/../../controllers/ProductController.php';
require __DIR__ . '/../../controllers/CategoryController.php';
require __DIR__ . '/../../controllers/UploadController.php';

// ── CORS: let the React dev server (port 5173) call us ──
header('Access-Control-Allow-Origin: http://localhost:5173');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$config = require __DIR__ . '/../../config.php';
$secret = $config['jwt_secret'];

// ── method + path after /shoear/api/v1 ──
$method = $_SERVER['REQUEST_METHOD'];
$uri    = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$base   = '/shoear/api/v1';
$path   = '/' . trim(substr($uri, strlen($base)), '/');

// ── public routes ──
if ($method === 'GET' && $path === '/ping') {
  sendJson(200, true, ['message' => 'pong', 'time' => date('c')]);
}

if ($method === 'GET' && $path === '/db-test') {
  $pdo  = getPDO();
  $stmt = $pdo->query('SELECT COUNT(*) AS total FROM product');
  $row  = $stmt->fetch();
  sendJson(200, true, ['productCount' => (int) $row['total']]);
}

if ($method === 'POST' && $path === '/auth/register') {
  $pdo = getPDO();
  handleRegister($pdo);
}

if ($method === 'POST' && $path === '/auth/login') {
  $pdo = getPDO();
  handleLogin($pdo, $secret);
}

// ── admin routes (require an Admin token) ──
if ($method === 'GET' && $path === '/admin/suppliers/pending') {
  $auth = requireAuth($secret);
  requireAdmin($auth);
  $pdo  = getPDO();
  handleListPendingSuppliers($pdo);
}

if ($method === 'POST' && preg_match('#^/admin/suppliers/([^/]+)/approve$#', $path, $m)) {
  $auth = requireAuth($secret);
  requireAdmin($auth);
  $pdo  = getPDO();
  handleApproveSupplier($pdo, $m[1]);
}

if ($method === 'POST' && preg_match('#^/admin/suppliers/([^/]+)/reject$#', $path, $m)) {
  $auth = requireAuth($secret);
  requireAdmin($auth);
  $pdo  = getPDO();
  handleRejectSupplier($pdo, $m[1]);
}

if ($method === 'GET' && $path === '/admin/products/pending') {
  $auth = requireAuth($secret);
  requireAdmin($auth);
  $pdo  = getPDO();
  handleListPendingProducts($pdo);
}

if ($method === 'POST' && preg_match('#^/admin/products/([^/]+)/approve$#', $path, $m)) {
  $auth = requireAuth($secret);
  requireAdmin($auth);
  $pdo  = getPDO();
  handleApproveProduct($pdo, $m[1]);
}

if ($method === 'POST' && preg_match('#^/admin/products/([^/]+)/reject$#', $path, $m)) {
  $auth = requireAuth($secret);
  requireAdmin($auth);
  $pdo  = getPDO();
  handleRejectProduct($pdo, $m[1]);
}

// ── category routes (require a valid token) ──
if ($method === 'GET' && $path === '/categories') {
  $auth = requireAuth($secret);
  $pdo  = getPDO();
  handleListCategories($pdo);
}

// ── file uploads (multipart): images + 3D models for products ──
if ($path === '/uploads' && $method === 'POST') {
  $auth = requireAuth($secret);
  $pdo  = getPDO();
  handleUpload($pdo, $auth);
}

// ── product routes (all require a valid token) ──
if ($path === '/products') {
  $auth = requireAuth($secret);
  $pdo  = getPDO();
  if ($method === 'GET')  handleListProducts($pdo, $auth);
  if ($method === 'POST') handleCreateProduct($pdo, $auth);
  sendJson(405, false, null, ['code' => 'METHOD', 'message' => 'Method not allowed.']);
}

if (preg_match('#^/products/([^/]+)$#', $path, $m)) {
  $id   = $m[1];
  $auth = requireAuth($secret);
  $pdo  = getPDO();
  if ($method === 'GET')    handleGetProduct($pdo, $auth, $id);
  if ($method === 'DELETE') handleDeleteProduct($pdo, $auth, $id);
  sendJson(405, false, null, ['code' => 'METHOD', 'message' => 'Method not allowed.']);
}

// ── nothing matched ──
sendJson(404, false, null, ['code' => 'NOT_FOUND', 'message' => "No route for $method $path"]);
