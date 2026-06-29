// Malaysian postcode → { city, state } lookup, mirroring the customer app's
// offline auto-fill. The dataset (public/my_postcodes.json, MIT-licensed Pos
// Malaysia data) is fetched once on first use and cached for the session, so
// typing a 5-digit postcode can auto-fill city + state with no API/cost.

let _cache = null;     // resolved postcode map
let _loading = null;   // in-flight fetch promise (dedupes concurrent calls)

function loadPostcodes() {
  if (_cache) return Promise.resolve(_cache);
  if (_loading) return _loading;
  _loading = fetch(`${import.meta.env.BASE_URL}my_postcodes.json`)
    .then((r) => (r.ok ? r.json() : null))
    .then((data) => {
      _cache = (data && data.postcodes) || {};
      return _cache;
    })
    .catch(() => {
      _cache = {};   // network/parse failure → behave as "no match", never throw
      return _cache;
    });
  return _loading;
}

// Resolve a 5-digit postcode to { city, state }, or null if unknown / invalid.
export async function lookupPostcode(postcode) {
  const code = String(postcode || '').trim();
  if (!/^\d{5}$/.test(code)) return null;
  const map = await loadPostcodes();
  return map[code] || null;
}
