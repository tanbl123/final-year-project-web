<?php
// Upload endpoint for the Supplier portal. Receives a single multipart file
// (an image or a 3D model), validates + stores it, and returns its public URL.
// The URL is then sent back when the supplier creates/updates a product.

// POST /uploads  (multipart/form-data: kind=image|model, file=<the file>)
function handleUpload(PDO $pdo, array $auth): void {
  // Only suppliers upload product assets (also confirms a supplier profile).
  requireSupplierId($pdo, $auth);

  $kind = $_POST['kind'] ?? $_GET['kind'] ?? '';
  if ($kind === '' || !isset($_FILES['file'])) {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'A "kind" and a "file" are required.']);
  }

  $url = storeUploadedFile($_FILES['file'], $kind);
  sendJson(201, true, ['url' => $url]);
}
