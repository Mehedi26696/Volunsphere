import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/auth_service.dart';
import '../services/events_service.dart';
import '../services/notification_service.dart';
import '../services/missed_message_service.dart';
import '../models/notification_model.dart';
import '../utils/api.dart';

class NotificationListenerService {
  static NotificationListenerService? _instance;
  static NotificationListenerService get instance => _instance ??= NotificationListenerService._();
  NotificationListenerService._();

  final Map<String, WebSocketChannel> _activeConnections = {};
  final Map<String, String> _eventTitles = {};
  Timer? _refreshTimer;
  String? _currentUserId;
  final Set<String> _activeChatSessions = {};

  Future<void> initialize() async {
    final tokenData = await AuthService.getTokenData();
    _currentUserId = tokenData?['sub'];
    
    if (_currentUserId == null) return;
    
    await _refreshJoinedEvents();
    
    // Refresh joined events every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _refreshJoinedEvents();
    });
    
    // Also check for missed messages every 2 minutes
    Timer.periodic(const Duration(minutes: 2), (_) {
      MissedMessageService.checkMissedMessages();
    });
  }

  Future<void> _refreshJoinedEvents() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final allEvents = await EventsService.getAllEvents();
      final joinedEvents = <String>[];

      for (final event in allEvents) {
        try {
          final attendees = await EventsService.getEventAttendees(event.id);
          if (attendees.any((a) => a['id'] == _currentUserId)) {
            joinedEvents.add(event.id);
            _eventTitles[event.id] = event.title;
          }
        } catch (e) {
          print('Error checking attendees for event ${event.id}: $e');
        }
      }

      print('Found ${joinedEvents.length} joined events: $joinedEvents');

      // Connect to new events
      for (final eventId in joinedEvents) {
        if (!_activeConnections.containsKey(eventId)) {
          await _connectToEvent(eventId, token);
        }
      }

      // Disconnect from events no longer joined
      final eventsToDisconnect = _activeConnections.keys
          .where((eventId) => !joinedEvents.contains(eventId))
          .toList();

      for (final eventId in eventsToDisconnect) {
        _disconnectFromEvent(eventId);
      }

      print('Active connections: ${_activeConnections.keys.toList()}');
    } catch (e) {
      print('Error refreshing joined events: $e');
    }
  }

  Future<void> _connectToEvent(String eventId, String token) async {
    try {
      final uri = Uri.parse('$chatUrl/ws/$eventId?token=$token');
      final channel = WebSocketChannel.connect(uri);

      channel.stream.listen(
        (data) {
          try {
            final jsonData = jsonDecode(data);
            print('Received message in event $eventId: $jsonData');
            _handleNewMessage(eventId, jsonData);
          } catch (e) {
            print('Failed to decode WebSocket message for event $eventId: $e');
          }
        },
        onDone: () {
          print('WebSocket closed for event $eventId');
          _activeConnections.remove(eventId);
          // Try to reconnect after 5 seconds
          Timer(const Duration(seconds: 5), () {
            if (_eventTitles.containsKey(eventId)) {
              _connectToEvent(eventId, token);
            }
          });
        },
        onError: (error) {
          print('WebSocket error for event $eventId: $error');
          _activeConnections.remove(eventId);
          // Try to reconnect after 10 seconds
          Timer(const Duration(seconds: 10), () {
            if (_eventTitles.containsKey(eventId)) {
              _connectToEvent(eventId, token);
            }
          });
        },
      );

      _activeConnections[eventId] = channel;
      print('Connected to event $eventId for notifications');
    } catch (e) {
      print('Error connecting to event $eventId: $e');
    }
  }

  void _disconnectFromEvent(String eventId) {
    final channel = _activeConnections.remove(eventId);
    channel?.sink.close();
    _eventTitles.remove(eventId);
    print('Disconnected from event $eventId');
  }

  Future<void> _handleNewMessage(String eventId, Map<String, dynamic> messageData) async {
    print('Handling message for event $eventId: $messageData');
    
    // Don't create notifications for own messages or if currently in that chat
    if (_activeChatSessions.contains(eventId)) {
      print('User is currently in chat for event $eventId, skipping notification');
      return;
    }

    if (messageData['userId'] == _currentUserId) {
      print('Message is from current user, skipping notification');
      return;
    }

    try {
      final eventTitle = _eventTitles[eventId] ?? 'Unknown Event';
      final senderName = messageData['username'] ?? messageData['user'] ?? 'Someone';
      
      print('Creating notification for event $eventId from $senderName');
      
      // Create notification with more unique ID
      final notification = NotificationModel(
        id: '${eventId}_${DateTime.now().millisecondsSinceEpoch}_${senderName.hashCode}',
        eventId: eventId,
        eventTitle: eventTitle,
        message: 'New message from $senderName',
        timestamp: DateTime.now(),
        type: 'new_message',
      );

      // Add to notification service
      await NotificationService.instance.addNotification(notification);
      print('Notification created successfully');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  void addActiveChatSession(String eventId) {
    _activeChatSessions.add(eventId);
    print('Added active chat session: $eventId. Active sessions: $_activeChatSessions');
  }

  void removeActiveChatSession(String eventId) {
    _activeChatSessions.remove(eventId);
    print('Removed active chat session: $eventId. Active sessions: $_activeChatSessions');
  }

  // Debug method to check current state
  void printDebugInfo() {
    print('=== Notification Listener Debug Info ===');
    print('Current User ID: $_currentUserId');
    print('Event Titles: $_eventTitles');
    print('Active Connections: ${_activeConnections.keys.toList()}');
    print('Active Chat Sessions: $_activeChatSessions');
    print('========================================');
  }

  void dispose() {
    _refreshTimer?.cancel();
    for (final channel in _activeConnections.values) {
      channel.sink.close();
    }
    _activeConnections.clear();
    _eventTitles.clear();
    _activeChatSessions.clear();
  }
}
