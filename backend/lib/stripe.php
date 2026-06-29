<?php
// Minimal Stripe REST client (no Composer dependency). Calls the Stripe API
// with the secret key via HTTP Basic auth. Throws RuntimeException on failure.
//
// NOTE: requires outbound network access to api.stripe.com and a valid test
// secret key in config ('stripe_secret'). With no key, stripeConfigured()
// returns false and callers should respond with STRIPE_NOT_CONFIGURED.

function stripeConfigured(array $config): bool {
  return !empty($config['stripe_secret']);
}

// $params is a (possibly nested) array; http_build_query renders Stripe's
// expected bracket notation, e.g. capabilities[transfers][requested]=true.
function stripeApi(string $secret, string $method, string $path, array $params = []): array {
  $ch = curl_init('https://api.stripe.com' . $path);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  curl_setopt($ch, CURLOPT_USERPWD, $secret . ':');
  curl_setopt($ch, CURLOPT_TIMEOUT, 30);

  if (strtoupper($method) === 'POST') {
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($params));
  } elseif (strtoupper($method) !== 'GET') {
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, strtoupper($method));
  }

  $raw  = curl_exec($ch);
  $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  $err  = curl_error($ch);
  curl_close($ch);

  if ($raw === false) {
    throw new RuntimeException('Could not reach Stripe: ' . $err);
  }
  $data = json_decode($raw, true);
  if (!is_array($data)) {
    throw new RuntimeException('Unexpected response from Stripe.');
  }
  if ($code >= 400) {
    throw new RuntimeException($data['error']['message'] ?? 'Stripe request failed.');
  }
  return $data;
}

// Params for creating a Connect account for a Malaysian platform.
//
// MY risk-control rules forbid the PLATFORM from being liable for losses. Stripe
// enforces this twice:
//   • `type: 'express'`  → platform is loss-liable          → rejected in MY.
//   • Express DASHBOARD  → also requires platform liability  → rejected in MY.
// So we use the Standard-account shape via `controller`: the CONNECTED account
// bears losses and pays fees, with a FULL Stripe dashboard. Onboarding stays
// Stripe-hosted via account links because requirement_collection = 'stripe'.
// (Standard accounts log in at dashboard.stripe.com — login_links don't apply.)
// $capabilities is e.g. ['transfers' => ['requested' => 'true']].
function stripeConnectAccountParams(array $capabilities): array {
  return [
    'country'      => 'MY',
    'capabilities' => $capabilities,
    'controller'   => [
      'losses'                 => ['payments' => 'stripe'],   // connected account bears losses, not the platform
      'fees'                   => ['payer' => 'account'],     // connected account pays Stripe fees
      'requirement_collection' => 'stripe',                   // Stripe collects requirements → hosted onboarding works
      'stripe_dashboard'       => ['type' => 'full'],         // Standard-style dashboard (express forces platform liability)
    ],
  ];
}
