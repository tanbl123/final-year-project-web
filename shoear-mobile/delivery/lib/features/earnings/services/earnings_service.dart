import 'package:delivery/core/api/api_client.dart';

/// Courier earnings + Stripe payout connection.
class EarningsService {
  final ApiClient api;
  EarningsService(this.api);

  /// GET /courier/earnings — balance, lifetime earned, fee, payout history,
  /// and Stripe connection status.
  Future<Map<String, dynamic>> earnings() async =>
      await api.get('/courier/earnings') as Map<String, dynamic>;

  /// POST /courier/stripe/onboard — returns a one-time hosted onboarding URL.
  Future<String> onboardUrl() async {
    final data = await api.post('/courier/stripe/onboard', {}) as Map<String, dynamic>;
    return data['url']?.toString() ?? '';
  }

  /// GET /courier/stripe/status — { connected, payoutsEnabled, ... }.
  Future<Map<String, dynamic>> stripeStatus() async =>
      await api.get('/courier/stripe/status') as Map<String, dynamic>;
}
