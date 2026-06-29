<?php
// ─────────────────────────────────────────────────────────────────────
// EasyParcel Open API — OAuth connect/callback/status/disconnect endpoints.
//
// The admin connects the platform's single EasyParcel account ONCE:
//   GET  /easyparcel/connect     (admin)  → { authorizeUrl }  — front-end then
//        redirects the browser there.
//   GET  /easyparcel/callback             → EasyParcel redirects the browser
//        back here with ?code&state; we exchange the code for tokens and 302
//        the browser back to the admin web app. (No JWT — it's a browser nav;
//        the one-time `state` is the CSRF guard.)
//   GET  /easyparcel/status      (admin)  → { configured, connected, ... }
//   POST /easyparcel/disconnect  (admin)  → clears the stored tokens.
//
// All booking logic lives in lib/easyparcel.php.
// ─────────────────────────────────────────────────────────────────────

// GET /easyparcel/status — is EasyParcel configured + connected? (admin)
function handleEasyParcelStatus(PDO $pdo, array $config): void {
  $row       = easyParcelLoadTokens($pdo);
  $connected = easyParcelConnected($pdo);
  sendJson(200, true, [
    'configured'       => easyParcelEnabled($config),
    'connected'        => $connected,
    'live'             => !empty($config['easyparcel_live']),
    'connectedAt'      => $row['connectedAt'] ?? null,
    'accountId'        => $row['accountId'] ?? null,
    'refreshExpiresAt' => $connected ? ($row['refreshExpiresAt'] ?? null) : null,
    'redirectUri'      => easyParcelRedirectUri($config),
  ]);
}

// GET /easyparcel/connect — generate a one-time state, return the consent URL. (admin)
function handleEasyParcelConnect(PDO $pdo, array $config): void {
  if (!easyParcelEnabled($config)) {
    sendJson(409, false, null, ['code' => 'NOT_CONFIGURED',
      'message' => 'EasyParcel app credentials are not set. Add easyparcel_client_id and easyparcel_client_secret to config.local.php first.']);
  }
  $state = bin2hex(random_bytes(16));
  easyParcelSetPendingState($pdo, $state);
  sendJson(200, true, ['authorizeUrl' => easyParcelAuthorizeUrl($config, $state)]);
}

// GET /easyparcel/callback?code&state — browser redirect target. Exchanges the
// code for tokens, then 302s back to the admin web app. NOT a JSON endpoint.
function handleEasyParcelCallback(PDO $pdo, array $config): void {
  $appBase  = rtrim((string) ($config['app_url'] ?? 'http://localhost:5173'), '/');
  $dest     = $appBase . '/admin/integrations';
  $bounce = function (string $status) use ($dest): void {
    header('Location: ' . $dest . '?easyparcel=' . $status);
    http_response_code(302);
    exit;
  };

  $code  = trim((string) ($_GET['code'] ?? ''));
  $state = trim((string) ($_GET['state'] ?? ''));
  if (isset($_GET['error']) || $code === '') { $bounce('denied'); }

  // Verify the one-time state we stashed before sending the admin off (CSRF),
  // and require it to be recent (15 min).
  $row     = easyParcelLoadTokens($pdo);
  $pending = (string) ($row['pendingState'] ?? '');
  $when    = $row['pendingStateAt'] ?? null;
  $fresh   = $when && (time() - strtotime((string) $when)) < 900;
  if ($pending === '' || !hash_equals($pending, $state) || !$fresh) { $bounce('badstate'); }

  $tok = easyParcelExchangeCode($config, $code, $state);
  if (!$tok || empty($tok['access_token']) || empty($tok['refresh_token'])) { $bounce('failed'); }

  easyParcelSaveTokens($pdo, $tok);
  $bounce('connected');
}

// POST /easyparcel/disconnect — clear stored tokens. (admin)
function handleEasyParcelDisconnect(PDO $pdo): void {
  easyParcelDisconnect($pdo);
  sendJson(200, true, ['connected' => false]);
}
