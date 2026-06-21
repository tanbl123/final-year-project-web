import '../api/api_client.dart';
import '../models/wishlist.dart';

/// Wishlist calls (all require a Customer token). Each returns the full wishlist.
class WishlistService {
  final ApiClient api;
  WishlistService(this.api);

  /// GET /wishlist
  Future<Wishlist> getWishlist() async =>
      Wishlist.fromJson(await api.get('/wishlist') as Map<String, dynamic>);

  /// POST /wishlist/items — save a product (idempotent).
  Future<Wishlist> add(String productId) async =>
      Wishlist.fromJson(await api.post('/wishlist/items', {'productId': productId}) as Map<String, dynamic>);

  /// DELETE /wishlist/items/{productId}
  Future<Wishlist> remove(String productId) async =>
      Wishlist.fromJson(await api.delete('/wishlist/items/$productId') as Map<String, dynamic>);
}
