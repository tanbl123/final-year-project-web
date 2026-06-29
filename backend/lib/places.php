<?php
// ─────────────────────────────────────────────────────────────────────
// Google Places (New) proxy for the web supplier address form.
//
// Mirrors the customer app's PlacesService, but server-side: the API key stays
// in config.local.php (never shipped to the browser) and there's no CORS issue.
// Progressive enhancement — when no key is configured every endpoint returns
// { enabled:false }, so the web form silently falls back to manual entry + the
// offline postcode → city/state lookup.
//
// Billing note: the frontend sends one session token per address entry, so a
// whole address (keystrokes + the final details call) is one billable session.
// ─────────────────────────────────────────────────────────────────────

function placesApiKey(array $config): string {
  return trim((string) ($config['google_places_api_key'] ?? ''));
}

// One HTTP call to the Places API. Returns [httpCode, decodedBodyArray|null].
function placesHttp(string $method, string $url, string $key, ?string $fieldMask, ?string $jsonBody): array {
  $headers = ['X-Goog-Api-Key: ' . $key];
  if ($fieldMask !== null) { $headers[] = 'X-Goog-FieldMask: ' . $fieldMask; }
  $ch = curl_init($url);
  $opts = [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 6,
    CURLOPT_HTTPHEADER     => $headers,
  ];
  if ($method === 'POST') {
    $opts[CURLOPT_POST] = true;
    $opts[CURLOPT_POSTFIELDS] = $jsonBody;
    $headers[] = 'Content-Type: application/json';
    $opts[CURLOPT_HTTPHEADER] = $headers;
  }
  curl_setopt_array($ch, $opts);
  $res  = curl_exec($ch);
  $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);
  return [$code, json_decode((string) $res, true)];
}

// Map Google's state name to the app's dropdown value, or '' if unrecognised.
function placesNormaliseState(string $g): string {
  $s = mb_strtolower($g);
  $map = [
    'kuala lumpur' => 'Kuala Lumpur', 'putrajaya' => 'Putrajaya', 'labuan' => 'Labuan',
    'penang' => 'Pulau Pinang', 'pinang' => 'Pulau Pinang',
    'malacca' => 'Melaka', 'melaka' => 'Melaka', 'negeri sembilan' => 'Negeri Sembilan',
    'johor' => 'Johor', 'kedah' => 'Kedah', 'kelantan' => 'Kelantan', 'pahang' => 'Pahang',
    'perak' => 'Perak', 'perlis' => 'Perlis', 'sabah' => 'Sabah', 'sarawak' => 'Sarawak',
    'selangor' => 'Selangor', 'terengganu' => 'Terengganu',
  ];
  foreach ($map as $needle => $name) {
    if (strpos($s, $needle) !== false) { return $name; }
  }
  return '';
}

// GET /places/autocomplete?q=...&session=... — address suggestions (Malaysia).
function handlePlacesAutocomplete(array $config): void {
  $key = placesApiKey($config);
  if ($key === '') { sendJson(200, true, ['enabled' => false, 'suggestions' => []]); }

  $q       = trim((string) ($_GET['q'] ?? ''));
  $session = trim((string) ($_GET['session'] ?? ''));
  if (mb_strlen($q) < 3) { sendJson(200, true, ['enabled' => true, 'suggestions' => []]); }

  $body = json_encode([
    'input'               => $q,
    'sessionToken'        => $session,
    'includedRegionCodes' => ['my'],
  ]);
  [$code, $data] = placesHttp('POST', 'https://places.googleapis.com/v1/places:autocomplete', $key, null, $body);
  if ($code !== 200 || !is_array($data)) { sendJson(200, true, ['enabled' => true, 'suggestions' => []]); }

  $out = [];
  foreach (($data['suggestions'] ?? []) as $s) {
    $pp = $s['placePrediction'] ?? null;
    if (!$pp) { continue; }
    $id   = $pp['placeId'] ?? '';
    $text = $pp['text']['text'] ?? '';
    $main = $pp['structuredFormat']['mainText']['text'] ?? '';
    if ($id !== '' && $text !== '') {
      $out[] = ['placeId' => $id, 'description' => $text, 'mainText' => $main];
    }
  }
  sendJson(200, true, ['enabled' => true, 'suggestions' => $out]);
}

// GET /places/details?placeId=...&session=... — resolved structured address.
function handlePlaceDetails(array $config): void {
  $key = placesApiKey($config);
  if ($key === '') { sendJson(200, true, ['enabled' => false, 'address' => null]); }

  $placeId = trim((string) ($_GET['placeId'] ?? ''));
  $session = trim((string) ($_GET['session'] ?? ''));
  if ($placeId === '') {
    sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'A placeId is required.']);
  }

  $url = 'https://places.googleapis.com/v1/places/' . rawurlencode($placeId)
       . '?sessionToken=' . urlencode($session);
  [$code, $data] = placesHttp('GET', $url, $key, 'addressComponents', null);
  if ($code !== 200 || !is_array($data)) { sendJson(200, true, ['enabled' => true, 'address' => null]); }

  $streetNumber = $route = $taman = $locality = $state = $postcode = '';
  foreach (($data['addressComponents'] ?? []) as $c) {
    $types    = $c['types'] ?? [];
    $longText = $c['longText'] ?? '';
    if (in_array('street_number', $types, true)) {
      $streetNumber = $longText;
    } elseif (in_array('route', $types, true)) {
      $route = $longText;
    } elseif ($taman === '' && (in_array('sublocality', $types, true)
        || in_array('sublocality_level_1', $types, true) || in_array('neighborhood', $types, true))) {
      $taman = $longText;
    } elseif (in_array('locality', $types, true)) {
      $locality = $longText;
    } elseif (in_array('administrative_area_level_1', $types, true)) {
      $state = $longText;
    } elseif (in_array('postal_code', $types, true)) {
      $postcode = $longText;
    }
  }

  $city = $locality !== '' ? $locality : $taman;
  $street = trim($streetNumber . ' ' . $route);
  $line1Parts = array_filter([$street, $taman], static fn($p) => $p !== '' && $p !== $city);
  $line1 = implode(', ', $line1Parts);

  sendJson(200, true, ['enabled' => true, 'address' => [
    'line1'    => $line1,
    'city'     => $city,
    'state'    => placesNormaliseState($state),
    'postcode' => $postcode,
  ]]);
}
