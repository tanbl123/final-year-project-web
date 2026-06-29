<?php
// ─────────────────────────────────────────────────────────────────────
// EasyParcel (Malaysia) shipping integration — auto-book a Standard parcel
// and get a carrier + tracking number, the way Shopee generates an airway bill.
//
// Progressive enhancement: only active when 'easyparcel_api_key' is configured.
// The flow is rate-check → submit order → pay (in the DEMO sandbox this is free
// and returns a test AWB). ANY failure returns null so the caller falls back to
// manual carrier + tracking entry — the demo never hard-breaks.
//
// Docs: https://developers.easyparcel.com (Malaysia API). Demo base:
// http://demo.connect.easyparcel.my/ ; live: https://connect.easyparcel.my/
// ─────────────────────────────────────────────────────────────────────

// Our state names → EasyParcel's state codes.
const EP_STATE_CODES = [
  'Johor' => 'jhr', 'Kedah' => 'kdh', 'Kelantan' => 'ktn', 'Melaka' => 'mlk',
  'Negeri Sembilan' => 'nsn', 'Pahang' => 'phg', 'Perak' => 'prk', 'Perlis' => 'pls',
  'Pulau Pinang' => 'png', 'Sabah' => 'sbh', 'Sarawak' => 'srw', 'Selangor' => 'sgr',
  'Terengganu' => 'trg', 'Kuala Lumpur' => 'kul', 'Labuan' => 'lbn', 'Putrajaya' => 'pjy',
];

function easyParcelEnabled(array $config): bool {
  return trim((string) ($config['easyparcel_api_key'] ?? '')) !== '';
}

function easyParcelBase(array $config): string {
  return !empty($config['easyparcel_live'])
    ? 'https://connect.easyparcel.my/'
    : 'http://demo.connect.easyparcel.my/';
}

function easyParcelStateCode(string $state): string {
  return EP_STATE_CODES[$state] ?? '';
}

// One form-encoded POST to an EasyParcel action. Returns the decoded array or null.
function easyParcelPost(array $config, string $action, array $fields): ?array {
  $fields['api'] = trim((string) ($config['easyparcel_api_key'] ?? ''));
  $ch = curl_init(easyParcelBase($config) . '?ac=' . $action);
  curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST           => true,
    CURLOPT_TIMEOUT        => 15,
    CURLOPT_POSTFIELDS     => http_build_query($fields),   // → bulk[0][field]=…
  ]);
  $res  = curl_exec($ch);
  $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);
  if ($code < 200 || $code >= 300) { return null; }
  $data = json_decode((string) $res, true);
  return is_array($data) ? $data : null;
}

// Book a shipment end to end. $sender/$receiver each:
//   [name, company, phone, line1, line2, city, state(full name), code(postcode)]
// $parcel: [weight, content, value]. Returns
//   ['carrier','tracking','tracking_url','awb_link'] or null on any failure.
function easyParcelBook(array $config, array $sender, array $receiver, array $parcel): ?array {
  if (!easyParcelEnabled($config)) { return null; }
  $pickState = easyParcelStateCode($sender['state'] ?? '');
  $sendState = easyParcelStateCode($receiver['state'] ?? '');
  if ($pickState === '' || $sendState === '') { return null; }
  $weight = (string) ($parcel['weight'] ?? '1');

  // 1) rate check → choose the cheapest service
  $rateResp = easyParcelPost($config, 'EPRateCheckingBulk', ['bulk' => [[
    'pick_code' => $sender['code'],   'pick_state' => $pickState, 'pick_country' => 'MY',
    'send_code' => $receiver['code'], 'send_state' => $sendState, 'send_country' => 'MY',
    'weight' => $weight, 'width' => '10', 'length' => '10', 'height' => '10',
  ]]]);
  $rates = $rateResp['result'][0]['rates'] ?? [];
  if (!is_array($rates) || !$rates) { return null; }
  usort($rates, static fn($a, $b) => (float) ($a['price'] ?? 0) <=> (float) ($b['price'] ?? 0));
  $svc       = $rates[0];
  $serviceId = $svc['service_id'] ?? '';
  $courier   = $svc['courier_name'] ?? ($svc['service_name'] ?? 'Courier');
  if ($serviceId === '') { return null; }

  // 2) submit the order
  $submitResp = easyParcelPost($config, 'EPSubmitOrderBulk', ['bulk' => [[
    'weight' => $weight, 'width' => '10', 'length' => '10', 'height' => '10',
    'content' => $parcel['content'] ?? 'Footwear', 'value' => (string) ($parcel['value'] ?? '0'),
    'service_id' => $serviceId,
    'pick_name' => $sender['name'], 'pick_company' => $sender['company'] ?? '',
    'pick_contact' => $sender['phone'], 'pick_mobile' => $sender['phone'],
    'pick_addr1' => $sender['line1'], 'pick_addr2' => $sender['line2'] ?? '',
    'pick_city' => $sender['city'], 'pick_state' => $pickState,
    'pick_code' => $sender['code'], 'pick_country' => 'MY',
    'send_name' => $receiver['name'], 'send_contact' => $receiver['phone'], 'send_mobile' => $receiver['phone'],
    'send_addr1' => $receiver['line1'], 'send_addr2' => $receiver['line2'] ?? '',
    'send_city' => $receiver['city'], 'send_state' => $sendState,
    'send_code' => $receiver['code'], 'send_country' => 'MY',
    // required by 1.4.0.0: pickup date (today), SMS flag, receiver email
    'collect_date' => date('Y-m-d'),
    'sms' => '0',
    'send_email' => $receiver['email'] ?? '',
  ]]]);
  $orderNo = $submitResp['result'][0]['order_number'] ?? ($submitResp['result'][0]['orderno'] ?? '');
  if ($orderNo === '') { return null; }

  // 3) pay the order → returns the AWB / tracking number (free in the demo sandbox)
  $payResp = easyParcelPost($config, 'EPPayOrderBulk', ['bulk' => [['order_no' => $orderNo]]]);
  $row = $payResp['result'][0]['parcel'][0] ?? ($payResp['result'][0] ?? []);
  $awb = $row['awb'] ?? ($row['tracking'] ?? '');
  if ($awb === '') { return null; }

  return [
    'carrier'      => $courier,
    'tracking'     => $awb,
    'tracking_url' => $row['tracking_url'] ?? '',
    'awb_link'     => $row['awb_id_link'] ?? '',
  ];
}
