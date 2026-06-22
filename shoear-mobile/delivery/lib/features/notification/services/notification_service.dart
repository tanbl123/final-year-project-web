import 'package:delivery/core/api/api_client.dart';

/// Registers this device's FCM token with the backend so the server can send
/// push notifications to this courier.
class NotificationService {
  final ApiClient _api;
  NotificationService(this._api);

  Future<void> registerDevice(String fcmToken) =>
      _api.post('/notifications/device', {'token': fcmToken});
}
