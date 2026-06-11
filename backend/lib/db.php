<?php
// Returns a configured PDO connection (or sends a 500 and stops).
function getPDO() {
  $config = require __DIR__ . '/../config.php';
  $db = $config['db'];
  $dsn = "mysql:host={$db['host']};port={$db['port']};dbname={$db['name']};charset={$db['charset']}";
  try {
    return new PDO($dsn, $db['user'], $db['pass'], [
      PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
      PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
      PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
  } catch (PDOException $e) {
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode(['success' => false, 'data' => null,
      'error' => ['code' => 'DB_CONNECTION', 'message' => $e->getMessage()]]);
    exit;
  }
}
