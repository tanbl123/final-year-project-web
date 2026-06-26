# Google Places address autocomplete — setup

The delivery-address field on the checkout screen can use **Google Places
Autocomplete** to suggest real addresses and auto-fill line 1, city, postcode,
and state.

This is a **progressive enhancement** and is **OFF by default**:

- **No API key** → autocomplete is disabled; checkout uses manual entry plus the
  offline postcode → city/state lookup (`assets/data/my_postcodes.json`).
- **API key provided** → typing the address shows live Google suggestions; the
  offline lookup remains as a fallback when offline or when Google omits a field.

So the app works fully with no key — the key only *adds* the autocomplete.

## How to enable it

### 1. Create the Google Cloud project + key
1. Go to <https://console.cloud.google.com/> and create a project.
2. Enable the **Places API (New)**.
3. Create an **API key** (APIs & Services → Credentials).
4. Attach a **billing account** (a card is required even for the free tier).
5. (Recommended) Restrict the key to the **Places API** and your app's
   package name / bundle id.

### 2. Run the app with the key (never hard-code it)
The key is read from a build-time variable, so it is **not** committed to git:

```bash
flutter run   --dart-define=GOOGLE_PLACES_API_KEY=AIzaSy...your-key...
flutter build --dart-define=GOOGLE_PLACES_API_KEY=AIzaSy...your-key...
```

That's it — no source changes needed. `lib/config.dart` reads the variable and
`googlePlacesEnabled` flips on automatically.

## Cost / quota (as of 2026)

- Billing model is **pay-as-you-go** with a **per-API free tier**: the
  Essentials SKU includes **10,000 free uses per month** (resets monthly).
- **Session tokens** group all keystrokes + the final details call into ONE
  billable use, so typing a whole address counts as a **single** use, not one
  per letter (handled automatically in `places_service.dart`).
- Typical project usage (a few hundred lookups) stays **well within the free
  tier → RM 0**. Verify current rates at
  <https://developers.google.com/maps/billing-and-pricing/pricing>.

## Why a bundled fallback is kept

Postcodes are static reference data, so the offline dataset gives a reliable
baseline that never fails (no network, no card, no rate limit). Google
autocomplete is layered on top for a richer experience when online. If Google
is unreachable or returns an incomplete address, the checkout degrades
gracefully to the offline lookup — it never blocks an order.

## Relevant files

| File | Role |
|---|---|
| `lib/config.dart` | Reads `GOOGLE_PLACES_API_KEY`; exposes `googlePlacesEnabled` |
| `lib/core/services/places_service.dart` | Autocomplete + Place Details (New Places API), state-name normalisation |
| `lib/core/services/postcode_service.dart` | Offline postcode → city/state fallback |
| `lib/features/checkout/screens/checkout_screen.dart` | Wires both into the address form |
