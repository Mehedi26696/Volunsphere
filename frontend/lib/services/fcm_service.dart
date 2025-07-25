import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/api.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class FcmService {
  static final FcmService instance = FcmService._();
  FcmService._();

  Future<void> initialize() async {
    // Get and send the initial FCM token
    await _sendTokenToBackend();

    // Listen for token refresh and send the new token to backend
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      await _sendTokenToBackend(token: newToken);
    });

    // Listen for foreground push notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Push notification: ${message.notification?.title}');
      // Add to NotificationService if notification payload exists
      if (message.notification != null) {
        final notification = NotificationModel(
          id:
              message.data['id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          eventId: message.data['event_id'] ?? '',
          eventTitle: message.notification?.title ?? '',
          message: message.notification?.body ?? '',
          timestamp: DateTime.now(),
          type: message.data['type'] ?? 'new_message',
        );
        await NotificationService.instance.addNotification(notification);
      }
    });
  }

  Future<void> _sendTokenToBackend({String? token}) async {
    final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken');
    final tokenData = await AuthService.getTokenData();
    final userId = tokenData != null ? tokenData['sub'] : null;
    if (userId != null && fcmToken != null) {
      final url = '$userUrl/$userId/fcm_token';
      try {
        final response = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: '{"fcm_token": "$fcmToken"}',
        );
        if (response.statusCode == 200) {
          print('FCM token sent to backend');
        } else {
          print(
            'Failed to send FCM token to backend: \\${response.statusCode} - \\${response.body}',
          );
        }
      } catch (e) {
        print('Failed to send FCM token to backend: $e');
      }
    }
  }
}
