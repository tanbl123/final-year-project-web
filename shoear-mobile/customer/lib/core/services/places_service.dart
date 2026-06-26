import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:customer/config.dart';

/// A single address suggestion shown under the address field.
class PlaceSuggestion {
  final String placeId;
  final String description; // full text incl. city/state (for the list row)
  final String mainText; // just the premise/street part (for address line 1)
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText = '',
  });
}

/// A resolved, structured address from a Place Details lookup. Any field may be
/// empty if Google didn't return it (the UI keeps those fields editable).
class PlaceAddress {
  final String line1; // street number + route (best effort)
  final String city;
  final String state; // normalised to the app's 16 dropdown names, or ''
  final String postcode;
  const PlaceAddress({
    this.line1 = '',
    this.city = '',
    this.state = '',
    this.postcode = '',
  });
}

/// Google Places (New) autocomplete for the delivery address.
///
/// Progressive enhancement: only active when a build-time API key is present
/// (see [googlePlacesEnabled]). When no key / no network, the checkout screen
/// falls back to manual entry plus the offline postcode -> city/state lookup,
/// so nothing breaks.
///
/// Billing note: keystrokes + the final details call are grouped into ONE
/// session via a session token, so typing a whole address counts as a single
/// billable use, not one-per-letter.
class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  static const _base = 'https://places.googleapis.com/v1';

  bool get enabled => googlePlacesEnabled;

  /// A fresh session token. Create one per address entry and discard it after
  /// [details] is called (that closes the billing session).
  String newSessionToken() {
    final r = Random();
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final rand =
        List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
    return 'sess-$ts-$rand';
  }

  /// Address suggestions for [input], restricted to Malaysia. Returns an empty
  /// list when disabled, on short input, or on any error (silent fallback).
  Future<List<PlaceSuggestion>> autocomplete(
      String input, String sessionToken) async {
    if (!enabled || input.trim().length < 3) return const [];
    try {
      final res = await http
          .post(
            Uri.parse('$_base/places:autocomplete'),
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': googlePlacesApiKey,
            },
            body: jsonEncode({
              'input': input,
              'sessionToken': sessionToken,
              'includedRegionCodes': ['my'],
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return const [];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final suggestions = (data['suggestions'] as List?) ?? const [];
      final out = <PlaceSuggestion>[];
      for (final s in suggestions) {
        final pp = (s as Map<String, dynamic>)['placePrediction']
            as Map<String, dynamic>?;
        if (pp == null) continue;
        final id = pp['placeId'] as String? ?? '';
        final text =
            (pp['text'] as Map<String, dynamic>?)?['text'] as String? ?? '';
        // structuredFormat.mainText is just the premise/street (no city/state).
        final sf = pp['structuredFormat'] as Map<String, dynamic>?;
        final mainText =
            (sf?['mainText'] as Map<String, dynamic>?)?['text'] as String? ??
                '';
        if (id.isNotEmpty && text.isNotEmpty) {
          out.add(PlaceSuggestion(
              placeId: id, description: text, mainText: mainText));
        }
      }
      return out;
    } catch (_) {
      return const []; // network/parse error -> fall back silently
    }
  }

  /// Structured address for a picked [placeId]. Returns null on any error.
  Future<PlaceAddress?> details(String placeId, String sessionToken) async {
    if (!enabled) return null;
    try {
      final uri = Uri.parse('$_base/places/$placeId')
          .replace(queryParameters: {'sessionToken': sessionToken});
      final res = await http.get(uri, headers: {
        'X-Goog-Api-Key': googlePlacesApiKey,
        'X-Goog-FieldMask': 'addressComponents',
      }).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final comps = (data['addressComponents'] as List?) ?? const [];

      String streetNumber = '', route = '', taman = '', locality = '',
          state = '', postcode = '';
      for (final c in comps) {
        final m = c as Map<String, dynamic>;
        final types = ((m['types'] as List?) ?? const []).cast<String>();
        final longText = m['longText'] as String? ?? '';
        if (types.contains('street_number')) {
          streetNumber = longText;
        } else if (types.contains('route')) {
          route = longText;
        } else if (taman.isEmpty &&
            (types.contains('sublocality') ||
                types.contains('sublocality_level_1') ||
                types.contains('neighborhood'))) {
          taman = longText; // e.g. "Taman Stulang"
        } else if (types.contains('locality')) {
          locality = longText;
        } else if (types.contains('administrative_area_level_1')) {
          state = longText;
        } else if (types.contains('postal_code')) {
          postcode = longText;
        }
      }
      // City is the locality; if Google didn't give one, fall back to the taman.
      final city = locality.isNotEmpty ? locality : taman;
      // Line 1 = street + taman (but never repeat whatever became the city).
      final street =
          [streetNumber, route].where((s) => s.isNotEmpty).join(' ');
      final line1 = [street, taman]
          .where((s) => s.isNotEmpty && s != city)
          .join(', ');
      return PlaceAddress(
        line1: line1,
        city: city,
        state: _normaliseState(state),
        postcode: postcode,
      );
    } catch (_) {
      return null;
    }
  }

  /// The premise portion of a suggestion's full [description] — i.e. everything
  /// before the trailing city / state / postcode / "Malaysia". This keeps parts
  /// like the taman/neighbourhood ("Taman Stulang") that Google often leaves
  /// out of the structured address components. [city] is the resolved locality
  /// (from Place Details) used to recognise the city token.
  String premiseFromDescription(String description, String city) {
    final tokens = description
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    while (tokens.isNotEmpty) {
      final last = tokens.last;
      final isPostcode = RegExp(r'^\d{5}$').hasMatch(last);
      final isCountry = last.toLowerCase() == 'malaysia';
      final isCity = city.isNotEmpty && last.toLowerCase() == city.toLowerCase();
      final isState = _normaliseState(last).isNotEmpty;
      if (isPostcode || isCountry || isCity || isState) {
        tokens.removeLast();
      } else {
        break; // reached the premise — stop trimming
      }
    }
    return tokens.join(', ');
  }

  /// Maps Google's state name (e.g. "Penang", "Federal Territory of Kuala
  /// Lumpur") to the app's dropdown value. Returns '' if unrecognised, leaving
  /// the state for the customer to pick manually.
  String _normaliseState(String g) {
    final s = g.toLowerCase();
    if (s.contains('kuala lumpur')) return 'Kuala Lumpur';
    if (s.contains('putrajaya')) return 'Putrajaya';
    if (s.contains('labuan')) return 'Labuan';
    if (s.contains('penang') || s.contains('pinang')) return 'Pulau Pinang';
    if (s.contains('malacca') || s.contains('melaka')) return 'Melaka';
    if (s.contains('negeri sembilan')) return 'Negeri Sembilan';
    if (s.contains('johor')) return 'Johor';
    if (s.contains('kedah')) return 'Kedah';
    if (s.contains('kelantan')) return 'Kelantan';
    if (s.contains('pahang')) return 'Pahang';
    if (s.contains('perak')) return 'Perak';
    if (s.contains('perlis')) return 'Perlis';
    if (s.contains('sabah')) return 'Sabah';
    if (s.contains('sarawak')) return 'Sarawak';
    if (s.contains('selangor')) return 'Selangor';
    if (s.contains('terengganu')) return 'Terengganu';
    return '';
  }
}
