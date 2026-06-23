import 'package:customer/core/api/api_client.dart';
import 'package:customer/features/cart/models/cart.dart';

/// Shopping cart calls (all require a Customer token). Every endpoint returns
/// the full, recomputed cart, so each call replaces our local copy.
class CartService {
  final ApiClient api;
  CartService(this.api);

  /// GET /cart
  Future<Cart> getCart() async => Cart.fromJson(await api.get('/cart') as Map<String, dynamic>);

  /// POST /cart/items — add (or top up) a size.
  Future<Cart> addItem(String variantId, int quantity) async =>
      Cart.fromJson(await api.post('/cart/items', {'variantId': variantId, 'quantity': quantity}) as Map<String, dynamic>);

  /// PUT /cart/items/{id} — set the exact quantity for a line.
  Future<Cart> updateItem(String cartItemId, int quantity) async =>
      Cart.fromJson(await api.put('/cart/items/$cartItemId', {'quantity': quantity}) as Map<String, dynamic>);

  /// DELETE /cart/items/{id}
  Future<Cart> removeItem(String cartItemId) async =>
      Cart.fromJson(await api.delete('/cart/items/$cartItemId') as Map<String, dynamic>);
}
