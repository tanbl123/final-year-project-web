// Google Places autocomplete for the address form, via our PHP proxy (the API
// key stays server-side). Progressive enhancement: if no key is configured the
// backend returns enabled:false and these return empty, so the form falls back
// to manual entry + the offline postcode lookup. All errors fail silently.
import { apiGet } from '../api/client';

// A fresh session token per address entry — groups the autocomplete keystrokes
// and the final details call into ONE billable Places session.
export function newSessionToken() {
  return 'sess-' + Date.now().toString(16) + '-' + Math.random().toString(16).slice(2, 10);
}

// Address suggestions for `query` (restricted to Malaysia by the backend).
export async function placesAutocomplete(query, session) {
  if (!query || query.trim().length < 3) return [];
  try {
    const data = await apiGet(
      `/places/autocomplete?q=${encodeURIComponent(query)}&session=${encodeURIComponent(session)}`,
    );
    return (data && data.enabled && data.suggestions) ? data.suggestions : [];
  } catch {
    return [];
  }
}

// Resolved structured address ({ line1, city, state, postcode }) for a picked
// suggestion, or null on any error / when Places is disabled.
export async function placeDetails(placeId, session) {
  try {
    const data = await apiGet(
      `/places/details?placeId=${encodeURIComponent(placeId)}&session=${encodeURIComponent(session)}`,
    );
    return (data && data.address) || null;
  } catch {
    return null;
  }
}
