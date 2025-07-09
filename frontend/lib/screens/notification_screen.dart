import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/events_service.dart';
import 'chat_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    // Force refresh the notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Trigger a setState to ensure the widget rebuilds with current data
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          children: [
                  // Modern header with gradient
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 60, 20, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF7B2CBF),
                          const Color(0xFF9D4EDD),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Consumer<NotificationService>(
                                builder: (context, notificationService, child) {
                                  final unreadCount = notificationService.unreadCount;
                                  return Text(
                                    unreadCount > 0 
                                        ? '$unreadCount new notification${unreadCount > 1 ? 's' : ''}'
                                        : 'All caught up!',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Modern action buttons
                  Consumer<NotificationService>(
                    builder: (context, notificationService, child) {
                      if (notificationService.notifications.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await notificationService.markAllAsRead();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.done_all_rounded, size: 18),
                                label: const Text('Mark all read'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B2CBF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  await notificationService.clearAllNotifications();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear_all_rounded, size: 18),
                                label: const Text('Clear all'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[600],
                                  side: BorderSide(color: Colors.red[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Notifications list
                  Expanded(
                    child: Consumer<NotificationService>(
                      builder: (context, notificationService, child) {
                        final notifications = notificationService.notifications;
                        
                        if (notifications.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    Icons.notifications_none_rounded,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'All caught up!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No new notifications at the moment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _buildModernNotificationItem(notification);
                          },
                        );
                      },
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _buildModernNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? Colors.white.withOpacity(0.95)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isRead 
              ? const Color(0xFF7B2CBF).withOpacity(0.1)
              : const Color(0xFF7B2CBF).withOpacity(0.2),
          width: notification.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: notification.isRead 
                ? const Color(0xFF7B2CBF).withOpacity(0.05)
                : const Color(0xFF7B2CBF).withOpacity(0.12),
            blurRadius: notification.isRead ? 8 : 15,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            // Mark as read first
            await _notificationService.markAsRead(notification.id);
            
            // Force UI refresh immediately
            if (mounted) {
              setState(() {});
            }
            
            // Navigate to chat screen
            await _navigateToChat(notification.eventId);
          },
          hoverColor: const Color(0xFF7B2CBF).withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: notification.isRead 
                          ? [Colors.grey[400]!, Colors.grey[500]!]
                          : [const Color(0xFF7B2CBF), const Color(0xFF9D4EDD)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event title and NEW badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.eventTitle,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 16,
                                color: const Color(0xFF27264A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE91E63).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Message text
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: const Color(0xFF626C7A),
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Timestamp with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: const Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeago.format(notification.timestamp),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF626C7A),
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Read indicator or arrow
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notification.isRead 
                        ? Colors.grey[100]
                        : const Color(0xFF7B2CBF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    notification.isRead 
                        ? Icons.check_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: notification.isRead 
                        ? Colors.grey[600]
                        : const Color(0xFF7B2CBF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToChat(String eventId) async {
    try {
      // Get event details and attendees
      final attendees = await EventsService.getEventAttendees(eventId);
      final events = await EventsService.getAllEvents();
      final event = events.firstWhere((e) => e.id == eventId);
      
      // Get creator info - look for creator in attendees list
      Map<String, dynamic>? creator;
      for (final attendee in attendees) {
        if (attendee['id'] == event.creatorId) {
          creator = attendee;
          break;
        }
      }
      
      // If creator not found in attendees, create a fallback
      if (creator == null) {
        creator = {
          'id': event.creatorId,
          'username': 'Event Creator',
          'email': 'creator@example.com'
        };
      }
      
      // Close notification panel
      if (mounted) {
        Navigator.of(context).pop();
        
        // Navigate to chat screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              eventId: eventId,
              attendees: attendees,
              creator: creator!,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening chat: $e')),
        );
      }
    }
  }
}
