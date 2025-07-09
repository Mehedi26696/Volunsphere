import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final List<NotificationModel> _notifications = [];
  final StreamController<List<NotificationModel>> _notificationController = 
      StreamController<List<NotificationModel>>.broadcast();

  List<NotificationModel> get notifications => _notifications;
  Stream<List<NotificationModel>> get notificationStream => _notificationController.stream;

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
      final notificationsJson = _notifications
          .map((n) => jsonEncode(n.toJson()))
          .toList();
      
      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  Future<void> addNotification(NotificationModel notification) async {
    print('Adding notification with ID: ${notification.id}');
    
    // Check if notification with same ID already exists
    final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);
    
    if (existingIndex != -1) {
      print('Notification with same ID already exists, skipping...');
      return;
    }
    
    // Add new notification at the beginning
    _notifications.insert(0, notification);
    print('Added new notification. Total count: ${_notifications.length}');
    
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
    
    await _saveNotifications();
    _notificationController.add(_notifications);
    notifyListeners();
    print('Notification service updated. Unread count: $unreadCount');
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

  void dispose() {
    _notificationController.close();
    super.dispose();
  }
}
