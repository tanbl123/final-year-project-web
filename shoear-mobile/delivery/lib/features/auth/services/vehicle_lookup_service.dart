import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:delivery/config.dart';

/// Fetches vehicle makes/models from the backend, which caches results in the
/// database. The backend serves data instantly from the DB on repeat requests
/// and fetches from NHTSA only on the very first call for a given type/make
/// (a one-time operation on the server, not the mobile client).
///
/// Malaysian brands (Perodua, Proton, Modenas, SYM) are pre-seeded in the DB
/// so they always appear even if the NHTSA call never succeeds.
///
/// If the backend is unreachable a small hardcoded fallback is returned so
/// registration is never completely blocked.
class VehicleLookupService {
  // Fallback for when the backend itself is down (e.g. running offline).
  static const Map<String, List<String>> _fallbackBrands = {
    'Motorcycle': ['Honda', 'Kawasaki', 'Modenas', 'Suzuki', 'SYM', 'Yamaha'],
    'Car':        ['Honda', 'Nissan', 'Perodua', 'Proton', 'Toyota'],
    'Van':        ['Nissan', 'Toyota'],
    'Truck':      ['Hino', 'Isuzu'],
  };

  /// All makes for the given vehicle type, sorted A–Z.
  Future<List<String>> makesForType(String vehicleType) async {
    try {
      final encoded = Uri.encodeComponent(vehicleType);
      final uri = Uri.parse('$apiBaseUrl/vehicles/makes/$encoded');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      return _parseList(res);
    } catch (_) {
      return List<String>.from(_fallbackBrands[vehicleType] ?? []);
    }
  }

  /// All models for the given type + make, sorted A–Z.
  /// Returns an empty list when the backend has no entry — VehiclePicker
  /// will automatically switch to free-text input.
  Future<List<String>> modelsForMake(String vehicleType, String make) async {
    try {
      final encodedType = Uri.encodeComponent(vehicleType);
      final encodedMake = Uri.encodeComponent(make);
      final uri = Uri.parse('$apiBaseUrl/vehicles/models/$encodedType/$encodedMake');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      return _parseList(res);
    } catch (_) {
      return [];
    }
  }

  List<String> _parseList(http.Response res) {
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] != true) return [];
    final data = body['data'];
    if (data is! List) return [];
    return data.map((e) => e.toString()).toList();
  }
}
