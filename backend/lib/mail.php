<?php
// Minimal SMTP mailer (no Composer). Sends an email through an authenticated
// SMTP server (e.g. Gmail) using the credentials in config['smtp']. Throws
// RuntimeException on any failure. Mirrors lib/stripe.php's "tiny hand-rolled
// client" style — we talk the SMTP protocol directly over a socket.
//
// NOTE: requires outbound network access to the SMTP host and valid credentials
// in config (set them in config.local.php — see config.local.example.php). With
// nothing configured, mailConfigured() returns false and callers respond with
// MAIL_NOT_CONFIGURED.

// Do we have everything we need to send mail?
function mailConfigured(array $config): bool {
  $s = $config['smtp'] ?? [];
  return !empty($s['host']) && !empty($s['username'])
      && !empty($s['password']) && !empty($s['from']);
}

// Read one full SMTP reply (handles multi-line replies: a line with a '-' after
// the 3-digit code continues; a space after the code marks the final line).
function smtpRead($fp): string {
  $data = '';
  while (($line = fgets($fp, 515)) !== false) {
    $data .= $line;
    if (isset($line[3]) && $line[3] === ' ') break;
  }
  return $data;
}

// Send a command (if any) and assert the reply code is one we expect.
function smtpCmd($fp, string $cmd, array $expect): string {
  if ($cmd !== '') fwrite($fp, $cmd . "\r\n");
  $resp = smtpRead($fp);
  $code = (int) substr($resp, 0, 3);
  if (!in_array($code, $expect, true)) {
    throw new RuntimeException('SMTP error: ' . trim($resp));
  }
  return $resp;
}

// RFC 2047-encode a header value only when it contains non-ASCII (so plain
// ASCII subjects/names stay human-readable on the wire).
function mimeHeader(string $text): string {
  if (preg_match('/[^\x20-\x7E]/', $text)) {
    return '=?UTF-8?B?' . base64_encode($text) . '?=';
  }
  return $text;
}

// Send a plain-text (optionally + HTML) email. Returns nothing; throws on error.
function sendMail(array $config, string $toEmail, string $toName,
                  string $subject, string $textBody, string $htmlBody = ''): void {
  if (!mailConfigured($config)) {
    throw new RuntimeException('Email is not configured on the server.');
  }
  $s       = $config['smtp'];
  $host    = $s['host'];
  $port    = (int) ($s['port'] ?? 587);
  $secure  = strtolower($s['secure'] ?? 'tls');   // 'tls' = STARTTLS (587); 'ssl' = implicit TLS (465)
  $ehlo    = $s['ehlo'] ?? 'localhost';
  $timeout = 30;

  // implicit-TLS connects over ssl:// from the start; STARTTLS upgrades later
  $remote = ($secure === 'ssl') ? "ssl://$host" : $host;
  $fp = @fsockopen($remote, $port, $errno, $errstr, $timeout);
  if (!$fp) {
    throw new RuntimeException("Could not connect to the SMTP server ($host:$port): $errstr");
  }
  stream_set_timeout($fp, $timeout);

  try {
    smtpCmd($fp, '', [220]);                       // server greeting
    smtpCmd($fp, "EHLO $ehlo", [250]);

    if ($secure === 'tls') {
      smtpCmd($fp, 'STARTTLS', [220]);
      if (!stream_socket_enable_crypto($fp, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
        throw new RuntimeException('Failed to start TLS with the SMTP server.');
      }
      smtpCmd($fp, "EHLO $ehlo", [250]);           // re-introduce ourselves over TLS
    }

    // AUTH LOGIN: username then password, each base64-encoded
    smtpCmd($fp, 'AUTH LOGIN', [334]);
    smtpCmd($fp, base64_encode($s['username']), [334]);
    smtpCmd($fp, base64_encode($s['password']), [235]);

    $fromEmail = $s['from'];
    $fromName  = $s['from_name'] ?? 'ShoeAR';
    smtpCmd($fp, "MAIL FROM:<$fromEmail>", [250]);
    smtpCmd($fp, "RCPT TO:<$toEmail>", [250, 251]);
    smtpCmd($fp, 'DATA', [354]);

    // ── build the MIME message ──
    $headers   = [];
    $headers[] = 'From: ' . mimeHeader($fromName) . " <$fromEmail>";
    $headers[] = 'To: ' . ($toName !== '' ? mimeHeader($toName) . " <$toEmail>" : "<$toEmail>");
    $headers[] = 'Subject: ' . mimeHeader($subject);
    $headers[] = 'Date: ' . date('r');
    $headers[] = 'MIME-Version: 1.0';

    if ($htmlBody !== '') {
      $boundary  = 'b' . bin2hex(random_bytes(8));
      $headers[] = "Content-Type: multipart/alternative; boundary=\"$boundary\"";
      $body  = "--$boundary\r\n";
      $body .= "Content-Type: text/plain; charset=UTF-8\r\n";
      $body .= "Content-Transfer-Encoding: 8bit\r\n\r\n";
      $body .= $textBody . "\r\n\r\n";
      $body .= "--$boundary\r\n";
      $body .= "Content-Type: text/html; charset=UTF-8\r\n";
      $body .= "Content-Transfer-Encoding: 8bit\r\n\r\n";
      $body .= $htmlBody . "\r\n\r\n";
      $body .= "--$boundary--";
    } else {
      $headers[] = 'Content-Type: text/plain; charset=UTF-8';
      $headers[] = 'Content-Transfer-Encoding: 8bit';
      $body = $textBody;
    }

    // normalise to CRLF, then dot-stuff lines that begin with '.'
    $message = implode("\r\n", $headers) . "\r\n\r\n" . $body;
    $message = preg_replace('/\r\n|\r|\n/', "\r\n", $message);
    $message = preg_replace('/^\./m', '..', $message);

    smtpCmd($fp, $message . "\r\n.", [250]);        // end-of-data is a lone '.'
    smtpCmd($fp, 'QUIT', [221]);
  } finally {
    fclose($fp);
  }
}

// Compose + send the registration verification-code email. Keeps the message
// copy in one place so both the controller and any future re-use stay tidy.
function sendVerificationCodeEmail(array $config, string $toEmail, string $code, int $ttlMinutes): void {
  $subject = 'Your ShoeAR verification code';
  $text =
    "Welcome to ShoeAR.\n\n" .
    "Your supplier registration verification code is: $code\n\n" .
    "Enter this code to finish creating your account. " .
    "It expires in $ttlMinutes minutes.\n\n" .
    "If you didn't request this, you can ignore this email.";
  $safeCode = htmlspecialchars($code, ENT_QUOTES);
  $html =
    '<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:auto">' .
    '<h2 style="margin:0 0 12px">👟 ShoeAR</h2>' .
    '<p>Welcome! Use this code to finish your supplier registration:</p>' .
    '<p style="font-size:32px;font-weight:bold;letter-spacing:6px;margin:16px 0">' . $safeCode . '</p>' .
    "<p style=\"color:#666\">It expires in $ttlMinutes minutes. " .
    'If you didn\'t request this, you can ignore this email.</p>' .
    '</div>';
  sendMail($config, $toEmail, '', $subject, $text, $html);
}
