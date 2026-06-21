import '../api/api_client.dart';
import '../models/order.dart';

/// Checkout, payment and receipt (all require a Customer token).
class OrderService {
  final ApiClient api;
  OrderService(this.api);

  /// The customer's saved shipping address (from their profile), used to
  /// prefill the checkout address. Null when they haven't set one.
  Future<String?> savedShippingAddress() async {
    final me = await api.get('/auth/me') as Map<String, dynamic>;
    final profile = me['profile'];
    if (profile is Map && profile['shippingAddress'] is String) {
      final s = (profile['shippingAddress'] as String).trim();
      return s.isEmpty ? null : s;
    }
    return null;
  }

  /// POST /orders — turn the cart into an order (Placed) and clear the cart.
  Future<CheckoutResult> checkout(String deliveryAddress) async => CheckoutResult.fromJson(
        await api.post('/orders', {'deliveryAddress': deliveryAddress}) as Map<String, dynamic>,
      );

  /// POST /orders/{id}/payment — simulated gateway; on success the order is Paid
  /// and dispatched. Throws [ApiException] on failure (e.g. out of stock).
  Future<void> pay(String orderId, String method) async {
    await api.post('/orders/$orderId/payment', {'paymentMethod': method});
  }

  /// GET /orders/{id}/receipt
  Future<Receipt> getReceipt(String orderId) async => Receipt.fromJson(
        await api.get('/orders/$orderId/receipt') as Map<String, dynamic>,
      );
}
