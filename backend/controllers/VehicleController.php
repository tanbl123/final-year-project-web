<?php
require_once __DIR__ . '/../lib/response.php';

// NHTSA type names for each of our vehicle types.
function _nhtsaType(string $vehicleType): string {
    return match ($vehicleType) {
        'Motorcycle'        => 'motorcycle',
        'Car'               => 'car',
        'Van', 'Truck'      => 'truck',
        default             => 'car',
    };
}

// Fetch a JSON array from NHTSA and return the named field from each result.
// Returns null on any network/parse error.
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

// GET /vehicles/makes/{vehicleType}
// Returns all makes for the given vehicle type from the DB.
// If the DB has no rows for that type yet, fetches from NHTSA once and stores.
// No auth required — called from the registration form.
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

    if (empty($makes)) {
        // DB empty for this type — fetch from NHTSA and cache.
        $nhtsaType = _nhtsaType($vehicleType);
        $url  = "https://vpic.nhtsa.dot.gov/api/vehicles/GetMakesForVehicleType/{$nhtsaType}?format=json";
        $fetched = _nhtsaFetch($url, 'MakeName');
        if ($fetched !== null) {
            $ins = $pdo->prepare(
                'INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES (?, ?)'
            );
            foreach ($fetched as $name) {
                $ins->execute([$vehicleType, $name]);
            }
            // Re-read so seeded local brands (e.g. Perodua) are included too.
            $stmt->execute([$vehicleType]);
            $makes = $stmt->fetchAll(PDO::FETCH_COLUMN);
        }
    }

    sendJson(200, true, array_values($makes));
}

// GET /vehicles/models/{vehicleType}/{make}
// Returns all models for the given type + make from the DB.
// If none exist yet, fetches from NHTSA once and stores.
// No auth required.
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

    if (empty($models)) {
        // Nothing cached — try NHTSA (works for international brands).
        $encoded = urlencode($make);
        $url  = "https://vpic.nhtsa.dot.gov/api/vehicles/GetModelsForMake/{$encoded}?format=json";
        $fetched = _nhtsaFetch($url, 'Model_Name');
        if ($fetched !== null && count($fetched) > 0) {
            $ins = $pdo->prepare(
                'INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES (?, ?, ?)'
            );
            foreach ($fetched as $name) {
                $ins->execute([$vehicleType, $make, $name]);
            }
            $stmt->execute([$vehicleType, $make]);
            $models = $stmt->fetchAll(PDO::FETCH_COLUMN);
        }
    }

    // Empty list is a valid response — VehiclePicker falls back to manual entry.
    sendJson(200, true, array_values($models));
}
