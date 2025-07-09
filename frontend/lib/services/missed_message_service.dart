import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/events_service.dart';
import '../services/notification_service.dart';
import '../services/authorized_request.dart';
import '../models/notification_model.dart';

class MissedMessageService {
  static const String _lastSeenPrefix = 'last_seen_';
  
  static Future<void> checkMissedMessages() async {
    try {
      final tokenData = await AuthService.getTokenData();
      final currentUserId = tokenData?['sub'];
      
      if (currentUserId == null) return;
      
      // Get all joined events
      final allEvents = await EventsService.getAllEvents();
      final joinedEvents = <String>[];
      
      for (final event in allEvents) {
        try {
          final attendees = await EventsService.getEventAttendees(event.id);
          if (attendees.any((a) => a['id'] == currentUserId)) {
            joinedEvents.add(event.id);
          }
        } catch (e) {
          print('Error checking attendees for event ${event.id}: $e');
        }
      }
      
      // Check for missed messages in each joined event
      for (final eventId in joinedEvents) {
        await _checkMissedMessagesForEvent(eventId, currentUserId);
      }
      
    } catch (e) {
      print('Error checking missed messages: $e');
    }
  }
  
  static Future<void> _checkMissedMessagesForEvent(String eventId, String currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenKey = '$_lastSeenPrefix$eventId';
      final lastSeenTimestamp = prefs.getString(lastSeenKey);
      
      // Get current user email for comparison
      final currentUserEmail = (await AuthService.getTokenData())?['email'];
      
      // Get messages from the event
      final response = await authorizedRequest(
        endpoint: '/chat/$eventId/messages',
        method: 'GET',
      );
      
      if (response.statusCode == 200) {
        final messages = jsonDecode(response.body) as List;
        
        DateTime? lastSeen;
        if (lastSeenTimestamp != null) {
          lastSeen = DateTime.parse(lastSeenTimestamp);
        }
        
        // Find messages that are newer than last seen and not from current user
        final missedMessages = messages.where((msg) {
          final messageTime = DateTime.parse(msg['timestamp']);
          final isFromCurrentUser = msg['email'] == currentUserEmail;
          
          return !isFromCurrentUser && 
                 (lastSeen == null || messageTime.isAfter(lastSeen));
        }).toList();
        
        // Create notifications for missed messages
        if (missedMessages.isNotEmpty) {
          final event = await _getEventById(eventId);
          final eventTitle = event?.title ?? 'Unknown Event';
          
          // Group messages by user to avoid spam
          final messagesByUser = <String, List<dynamic>>{};
          for (final msg in missedMessages) {
            final username = msg['username'] ?? 'Someone';
            messagesByUser[username] = (messagesByUser[username] ?? [])..add(msg);
          }
          
          // Create one notification per user who sent messages
          for (final entry in messagesByUser.entries) {
            final username = entry.key;
            final userMessages = entry.value;
            
            final notification = NotificationModel(
              id: '${eventId}_${DateTime.parse(userMessages.last['timestamp']).millisecondsSinceEpoch}_${username.hashCode}',
              eventId: eventId,
              eventTitle: eventTitle,
              message: userMessages.length == 1 
                  ? 'New message from $username'
                  : '${userMessages.length} new messages from $username',
              timestamp: DateTime.parse(userMessages.last['timestamp']),
              type: 'new_message',
            );
            
            await NotificationService.instance.addNotification(notification);
          }
        }
        
        // Update last seen timestamp to the latest message
        if (messages.isNotEmpty) {
          final latestMessage = messages.last;
          final latestTimestamp = latestMessage['timestamp'];
          await prefs.setString(lastSeenKey, latestTimestamp);
        }
      }
      
    } catch (e) {
      print('Error checking missed messages for event $eventId: $e');
    }
  }
  
  static Future<dynamic> _getEventById(String eventId) async {
    try {
      final allEvents = await EventsService.getAllEvents();
      return allEvents.firstWhere((e) => e.id == eventId);
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> markEventAsRead(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenKey = '$_lastSeenPrefix$eventId';
      await prefs.setString(lastSeenKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error marking event as read: $e');
    }
  }
  
  static Future<void> clearLastSeenForEvent(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenKey = '$_lastSeenPrefix$eventId';
      await prefs.remove(lastSeenKey);
    } catch (e) {
      print('Error clearing last seen for event: $e');
    }
  }
}
