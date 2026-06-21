import 'package:flutter/foundation.dart';

import '../models/wishlist.dart';
import '../services/wishlist_service.dart';

/// Holds the customer's wishlist. Keeps a set of saved product ids so any screen
/// can cheaply show a filled/empty heart. Loads on login, clears on logout.
class WishlistProvider extends ChangeNotifier {
  final WishlistService _service;
  WishlistProvider(this._service);

  Wishlist? _wishlist;
  Wishlist? get wishlist => _wishlist;
  int get count => _wishlist?.itemCount ?? 0;

  Set<String> _savedIds = {};
  bool isSaved(String productId) => _savedIds.contains(productId);

  bool _loading = false;
  bool get loading => _loading;
  String? error;

  bool? _wasLoggedIn;

  void syncWithAuth(bool loggedIn) {
    if (_wasLoggedIn == loggedIn) return;
    _wasLoggedIn = loggedIn;
    if (loggedIn) {
      Future.microtask(refresh);
    } else {
      _wishlist = null;
      _savedIds = {};
      error = null;
      Future.microtask(notifyListeners);
    }
  }

  void _syncIds() => _savedIds = _wishlist?.items.map((e) => e.productId).toSet() ?? {};

  Future<void> refresh() async {
    _loading = true;
    error = null;
    notifyListeners();
    try {
      _wishlist = await _service.getWishlist();
      _syncIds();
    } catch (e) {
      error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(String productId) async {
    _wishlist = await _service.add(productId);
    _syncIds();
    notifyListeners();
  }

  Future<void> remove(String productId) async {
    _wishlist = await _service.remove(productId);
    _syncIds();
    notifyListeners();
  }

  /// Heart toggle — throws [ApiException] on failure (the caller shows it).
  Future<void> toggle(String productId) =>
      isSaved(productId) ? remove(productId) : add(productId);
}
