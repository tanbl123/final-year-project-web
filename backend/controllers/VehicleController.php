<?php
require_once __DIR__ . '/../lib/response.php';

// How many days before cached data is considered stale and re-fetched.
const VEHICLE_CACHE_TTL_DAYS = 30;

// ── Helpers ───────────────────────────────────────────────────────────────────

function _nhtsaType(string $vehicleType): string {
    return match ($vehicleType) {
        'Motorcycle'   => 'motorcycle',
        'Car'          => 'car',
        'Van', 'Truck' => 'truck',
        default        => 'car',
    };
}

// Pull the named field from every NHTSA Results row.
// Returns a sorted, deduplicated list, or null on network/parse failure.
function _nhtsaFetch(string $url, string $field): ?array {
    $ctx = stream_context_create(['http' => [
        'timeout' => 25,
        'header'  => "User-Agent: ShoeARExpress/1.0\r\nAccept: application/json\r\n",
    ]]);
    $raw = @file_get_contents($url, false, $ctx);
    if ($raw === false) return null;
    $body = json_decode($raw, true);
    if (!is_array($body['Results'] ?? null)) return null;
    $names = array_values(array_unique(array_filter(
        array_map(fn($r) => trim($r[$field] ?? ''), $body['Results'])
    )));
    sort($names);
    return $names;
}

// True if the cache key has never been set or is older than VEHICLE_CACHE_TTL_DAYS.
function _isCacheStale(PDO $pdo, string $key): bool {
    $stmt = $pdo->prepare(
        'SELECT DATEDIFF(NOW(), cachedAt) FROM vehicle_cache_log WHERE cacheKey = ?'
    );
    $stmt->execute([$key]);
    $days = $stmt->fetchColumn();
    return $days === false || (int)$days >= VEHICLE_CACHE_TTL_DAYS;
}

function _touchCache(PDO $pdo, string $key): void {
    $pdo->prepare(
        'INSERT INTO vehicle_cache_log (cacheKey, cachedAt) VALUES (?, NOW())
         ON DUPLICATE KEY UPDATE cachedAt = NOW()'
    )->execute([$key]);
}

// Send the JSON response to the client and disconnect — background work can
// continue afterwards without making the user wait.
function _sendAndDetach(mixed $data): void {
    $body = json_encode(['success' => true, 'data' => $data, 'error' => null]);
    header('Content-Type: application/json');
    header('Content-Length: ' . strlen($body));
    header('Connection: close');
    echo $body;

    if (function_exists('fastcgi_finish_request')) {
        // PHP-FPM: closes the client connection immediately.
        fastcgi_finish_request();
    } else {
        // Apache mod_php: flush all output buffers so the client receives it.
        ignore_user_abort(true);
        while (ob_get_level() > 0) ob_end_flush();
        flush();
    }
}

// ── Route handlers ────────────────────────────────────────────────────────────

// GET /vehicles/makes/{vehicleType}
// Stale-while-revalidate: always returns cached DB data immediately, then
// refreshes from NHTSA in the background when the cache is >30 days old.
// No auth required — called from the courier registration form.
function handleGetVehicleMakes(PDO $pdo, string $vehicleType): void {
    $allowed = ['Motorcycle', 'Car', 'Van', 'Truck'];
    if (!in_array($vehicleType, $allowed, true)) {
        sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Unknown vehicle type.']);
        return;
    }

    $stmt = $pdo->prepare(
        'SELECT makeName FROM vehicle_makes WHERE vehicleType = ? ORDER BY makeName'
    );
    $stmt->execute([$vehicleType]);
    $makes = $stmt->fetchAll(PDO::FETCH_COLUMN);
    $cacheKey = 'makes_' . $vehicleType;

    if (empty($makes)) {
        // DB is completely empty (e.g. before seed SQL is run).
        // Fetch synchronously so the user gets something on first launch.
        $nhtsaType = _nhtsaType($vehicleType);
        $url = "https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/{$nhtsaType}?format=json";
        $fetched = _nhtsaFetch($url, 'MakeName');
        if ($fetched !== null) {
            $ins = $pdo->prepare(
                'INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES (?, ?)'
            );
            foreach ($fetched as $name) $ins->execute([$vehicleType, $name]);
            _touchCache($pdo, $cacheKey);
            $stmt->execute([$vehicleType]);
            $makes = $stmt->fetchAll(PDO::FETCH_COLUMN);
        }
        sendJson(200, true, array_values($makes));
        return;
    }

    // DB has data — send it to the client immediately.
    _sendAndDetach(array_values($makes));

    // Background: refresh from NHTSA if cache is stale (>30 days).
    if (_isCacheStale($pdo, $cacheKey)) {
        $nhtsaType = _nhtsaType($vehicleType);
        $url = "https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/{$nhtsaType}?format=json";
        $fetched = _nhtsaFetch($url, 'MakeName');
        if ($fetched !== null) {
            $ins = $pdo->prepare(
                'INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES (?, ?)'
            );
            foreach ($fetched as $name) $ins->execute([$vehicleType, $name]);
            _touchCache($pdo, $cacheKey);
        }
    }
}

// GET /vehicles/models/{vehicleType}/{make}
// Same stale-while-revalidate pattern as makes.
function handleGetVehicleModels(PDO $pdo, string $vehicleType, string $make): void {
    $allowed = ['Motorcycle', 'Car', 'Van', 'Truck'];
    if (!in_array($vehicleType, $allowed, true)) {
        sendJson(400, false, null, ['code' => 'VALIDATION', 'message' => 'Unknown vehicle type.']);
        return;
    }

    $stmt = $pdo->prepare(
        'SELECT modelName FROM vehicle_models WHERE vehicleType = ? AND makeName = ? ORDER BY modelName'
    );
    $stmt->execute([$vehicleType, $make]);
    $models = $stmt->fetchAll(PDO::FETCH_COLUMN);
    $cacheKey = 'models_' . $vehicleType . '_' . $make;

    if (empty($models)) {
        // Nothing cached — try NHTSA synchronously (covers international brands).
        $url = "https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMake/"
             . urlencode($make) . "?format=json";
        $fetched = _nhtsaFetch($url, 'Model_Name');
        if ($fetched !== null && count($fetched) > 0) {
            $ins = $pdo->prepare(
                'INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES (?, ?, ?)'
            );
            foreach ($fetched as $name) $ins->execute([$vehicleType, $make, $name]);
            _touchCache($pdo, $cacheKey);
            $stmt->execute([$vehicleType, $make]);
            $models = $stmt->fetchAll(PDO::FETCH_COLUMN);
        }
        // Empty list is valid — VehiclePicker switches to free-text.
        sendJson(200, true, array_values($models));
        return;
    }

    // DB has data — send immediately.
    _sendAndDetach(array_values($models));

    // Background: refresh from NHTSA if stale.
    if (_isCacheStale($pdo, $cacheKey)) {
        $url = "https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMake/"
             . urlencode($make) . "?format=json";
        $fetched = _nhtsaFetch($url, 'Model_Name');
        if ($fetched !== null && count($fetched) > 0) {
            $ins = $pdo->prepare(
                'INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES (?, ?, ?)'
            );
            foreach ($fetched as $name) $ins->execute([$vehicleType, $make, $name]);
            _touchCache($pdo, $cacheKey);
        }
    }
}
