<?php
// Generate the next prefixed string ID for a table, e.g. PRD0001 -> PRD0002.
function nextId(PDO $pdo, string $table, string $col, string $prefix): string {
  $stmt = $pdo->query("SELECT MAX(`$col`) AS maxId FROM `$table`");
  $row = $stmt->fetch();
  $num = $row['maxId'] ? (int) substr($row['maxId'], strlen($prefix)) : 0;
  return $prefix . str_pad((string) ($num + 1), 4, '0', STR_PAD_LEFT);
}
