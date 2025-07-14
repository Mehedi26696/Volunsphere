import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../utils/api.dart';
import 'auth_service.dart';

class NotificationService extends ChangeNotifier {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final List<NotificationModel> _notifications = [];
  final StreamController<List<NotificationModel>> _notificationController =
      StreamController<List<NotificationModel>>.broadcast();

  List<NotificationModel> get notifications => _notifications;
  Stream<List<NotificationModel>> get notificationStream =>
      _notificationController.stream;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];

      _notifications.clear();
      for (final jsonString in notificationsJson) {
        final notification = NotificationModel.fromJson(jsonDecode(jsonString));
        _notifications.add(notification);
      }

      // Sort by timestamp (newest first)
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _notificationController.add(_notifications);
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          _notifications.map((n) => jsonEncode(n.toJson())).toList();

      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  /// Only allow adding notifications from backend fetch.
  /// This disables local-only notifications to ensure only backend notifications are shown.
  Future<void> addNotification(NotificationModel notification) async {
    // Instead of adding locally, always fetch from backend to ensure only backend notifications are shown.
    print(
      'addNotification called. Fetching notifications from backend to enforce backend-only notifications.',
    );
    await fetchNotificationsFromBackend();
  }

  Future<void> markAsRead(String notificationId) async {
    print('=== Mark as Read Debug ===');
    print('Looking for notification ID: $notificationId');
    print('Total notifications: ${_notifications.length}');

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    print('Found notification at index: $index');

    if (index != -1) {
      final oldNotification = _notifications[index];
      print('Old notification isRead: ${oldNotification.isRead}');

      _notifications[index] = _notifications[index].copyWith(isRead: true);

      print('New notification isRead: ${_notifications[index].isRead}');
      print('Unread count before save: $unreadCount');

      await _saveNotifications();
      _notificationController.add(_notifications);
      notifyListeners();

      print('Unread count after save: $unreadCount');
      print('========================');
    } else {
      print('ERROR: Notification not found with ID: $notificationId');
      print('Available IDs: ${_notifications.map((n) => n.id).toList()}');
      print('========================');
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    await _saveNotifications();
    _notificationController.add(_notifications);
    notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    _notificationController.add(_notifications);
    notifyListeners();
  }

  Future<void> fetchNotificationsFromBackend() async {
    final tokenData = await AuthService.getTokenData();
    final userId = tokenData != null ? tokenData['sub'] : null;
    if (userId == null) return;
    final url = '$baseUrl/notifications/$userId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _notifications.clear();
        for (final item in data) {
          _notifications.add(NotificationModel.fromJson(item));
        }
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        await _saveNotifications();
        _notificationController.add(_notifications);
        notifyListeners();
      } else {
        print('Failed to fetch notifications: \\${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> markAsReadBackend(String notificationId) async {
    final url = '$baseUrl/notifications/$notificationId/read';
    try {
      await http.post(Uri.parse(url));
      await markAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read in backend: $e');
    }
  }

  /// Send notification to multiple users
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String message,
    String? eventId,
    String? eventTitle,
    String type = "new_message",
  }) async {
    final url = '$baseUrl/notifications/';
    final body = jsonEncode({
      'user_ids': userIds,
      'event_id': eventId,
      'event_title': eventTitle,
      'message': message,
      'type': type,
    });
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Notification sent to users');
      } else {
        print(
          'Failed to send notification: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  void dispose() {
    _notificationController.close();
    super.dispose();
  }
}
