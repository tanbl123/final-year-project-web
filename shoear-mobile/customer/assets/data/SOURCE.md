# Postcode dataset source

`my_postcodes.json` is a Malaysian postcode → city → state lookup used by the
checkout screen to auto-fill the city and state when a customer enters their
postcode.

## Provenance

- **Source dataset:** [AsyrafHussin/malaysia-postcodes](https://github.com/AsyrafHussin/malaysia-postcodes)
- **License:** MIT
- **Origin of the data:** Mirrors the official Malaysian postcode system
  published by **Pos Malaysia** (the national postal authority).
- **Raw file downloaded:** `https://raw.githubusercontent.com/AsyrafHussin/malaysia-postcodes/main/all.json`
- **Date downloaded:** 2026-06-25
- **Records:** 2,929 postcodes across all 16 Malaysian states and federal
  territories.

## Processing applied

The source file is organised hierarchically (`state → city → [postcodes]`).
It was flattened into a direct `postcode → { city, state }` map (sorted by
postcode) so the app can do an O(1) lookup. The three federal-territory names
were normalised to match the app's state dropdown:

| Source name        | App dropdown name |
|--------------------|-------------------|
| `Wp Kuala Lumpur`  | `Kuala Lumpur`    |
| `Wp Labuan`        | `Labuan`          |
| `Wp Putrajaya`     | `Putrajaya`       |

All other state names already matched exactly.

## Why bundled offline (instead of a live API)

Malaysian postcodes are static reference data, so the dataset is bundled as an
app asset and read locally. This keeps checkout working without a network
dependency and avoids any third-party API rate limit or outage. Unknown
postcodes fall back to manual city/state entry, so checkout is never blocked.

## Updating

To refresh the data, re-download `all.json` from the source repository above
and re-run the same flatten + state-name normalisation, then `flutter pub get`.
