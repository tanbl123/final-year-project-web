import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';

/// Holds the customer's cart. The cart lives server-side (one per customer), so
/// every mutation returns the fresh cart which we store and broadcast. The cart
/// only exists for a signed-in customer, so it loads on login and clears on
/// logout (driven by [syncWithAuth] from the auth state).
class CartProvider extends ChangeNotifier {
  final CartService _service;
  CartProvider(this._service);

  Cart? _cart;
  Cart? get cart => _cart;
  int get count => _cart?.itemCount ?? 0;

  bool _loading = false;
  bool get loading => _loading;
  String? error;

  bool? _wasLoggedIn;

  /// Called when the auth state changes: load the cart on login, drop it on
  /// logout. Work is deferred to a microtask so it never runs during a build.
  void syncWithAuth(bool loggedIn) {
    if (_wasLoggedIn == loggedIn) return;
    _wasLoggedIn = loggedIn;
    if (loggedIn) {
      Future.microtask(refresh);
    } else {
      _cart = null;
      error = null;
      Future.microtask(notifyListeners);
    }
  }

  Future<void> refresh() async {
    _loading = true;
    error = null;
    notifyListeners();
    try {
      _cart = await _service.getCart();
    } catch (e) {
      error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Throws [ApiException] (e.g. out of stock) — the caller shows the message.
  Future<void> add(String variantId, {int quantity = 1}) async {
    _cart = await _service.addItem(variantId, quantity);
    notifyListeners();
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    _cart = await _service.updateItem(cartItemId, quantity);
    notifyListeners();
  }

  Future<void> remove(String cartItemId) async {
    _cart = await _service.removeItem(cartItemId);
    notifyListeners();
  }
}
