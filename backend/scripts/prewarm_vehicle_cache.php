<?php
/**
 * Vehicle cache pre-warmer
 * ------------------------
 * Run this ONCE after a fresh DB setup to populate vehicle makes + models
 * for all vehicle types so every user gets instant dropdowns.
 *
 * Usage (browser):  http://localhost/shoear/backend/scripts/prewarm_vehicle_cache.php
 * Usage (CLI):      php backend/scripts/prewarm_vehicle_cache.php
 *
 * Takes 8-20 minutes depending on NHTSA response times. Leave it running.
 * Safe to re-run — skips brands whose models are already cached and fresh.
 */

set_time_limit(0);
ignore_user_abort(true);

// Flush output to browser line-by-line so progress is visible.
if (ob_get_level() === 0) ob_start();

require_once __DIR__ . '/../lib/db.php';
require_once __DIR__ . '/../controllers/VehicleController.php';

$isCli = PHP_SAPI === 'cli';

function out(string $msg): void {
    global $isCli;
    $line = $isCli ? $msg . "\n" : nl2br($msg) . "\n";
    echo $line;
    if (!$isCli) {
        ob_flush();
        flush();
    }
}

// ── NHTSA type map (same as VehicleController) ────────────────────────────────
$vehicleTypes = ['Motorcycle', 'Car', 'Van', 'Truck'];

$pdo = getPDO();

$totalMakes  = 0;
$totalModels = 0;
$skipped     = 0;
$failed      = 0;
$start       = microtime(true);

out("=== Vehicle cache pre-warmer ===");
out("Started: " . date('Y-m-d H:i:s'));
out("");

foreach ($vehicleTypes as $vehicleType) {
    out("── {$vehicleType} ──────────────────────────────────");

    // Step 1: ensure makes are cached for this type.
    $makesCacheKey = 'makes_' . $vehicleType;
    if (_isCacheStale($pdo, $makesCacheKey)) {
        out("  Fetching {$vehicleType} makes from NHTSA...");
        _replaceMakesFromNhtsa($pdo, $vehicleType, $makesCacheKey);
        out("  Makes cached.");
    } else {
        out("  Makes cache is fresh — skipping NHTSA fetch.");
    }

    // Step 2: fetch all makes from DB (local + nhtsa combined).
    $stmt = $pdo->prepare('SELECT makeName FROM vehicle_makes WHERE vehicleType = ? ORDER BY makeName');
    $stmt->execute([$vehicleType]);
    $makes = $stmt->fetchAll(PDO::FETCH_COLUMN);
    out("  " . count($makes) . " brands found.");
    $totalMakes += count($makes);
    out("");

    // Step 3: for each make, ensure models are cached.
    foreach ($makes as $i => $make) {
        $modelsCacheKey = 'models_' . $vehicleType . '_' . $make;
        $idx = $i + 1;

        if (!_isCacheStale($pdo, $modelsCacheKey)) {
            out("  [{$idx}/" . count($makes) . "] {$make} — already cached, skipping.");
            $skipped++;
            continue;
        }

        out("  [{$idx}/" . count($makes) . "] {$make} — fetching from NHTSA...");

        // Check how many models existed before.
        $before = $pdo->prepare('SELECT COUNT(*) FROM vehicle_models WHERE vehicleType = ? AND makeName = ?');
        $before->execute([$vehicleType, $make]);
        $countBefore = (int)$before->fetchColumn();

        _replaceModelsFromNhtsa($pdo, $vehicleType, $make, $modelsCacheKey);

        $after = $pdo->prepare('SELECT COUNT(*) FROM vehicle_models WHERE vehicleType = ? AND makeName = ?');
        $after->execute([$vehicleType, $make]);
        $countAfter = (int)$after->fetchColumn();

        if ($countAfter === 0 && $countBefore === 0) {
            out("  [{$idx}/" . count($makes) . "] {$make} — no models in NHTSA (normal for some brands).");
            $failed++;
        } else {
            out("  [{$idx}/" . count($makes) . "] {$make} — {$countAfter} models cached.");
            $totalModels += $countAfter;
        }

        // Small delay to avoid hammering NHTSA.
        sleep(1);
    }

    out("");
}

$elapsed = round(microtime(true) - $start);
$mins    = intdiv($elapsed, 60);
$secs    = $elapsed % 60;

out("=== Done ===");
out("Finished:      " . date('Y-m-d H:i:s'));
out("Time taken:    {$mins}m {$secs}s");
out("Total brands:  {$totalMakes}");
out("Total models:  {$totalModels}");
out("Skipped:       {$skipped} (already cached)");
out("No NHTSA data: {$failed} (brands not in NHTSA — normal)");
out("");
out("All users will now get instant dropdowns.");
