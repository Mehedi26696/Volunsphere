import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventActions extends StatelessWidget {
  final Event event;
  final bool isCreator;
  final bool isPastEvent;
  final bool isGuest;
  final bool hasJoined;
  final List<Map<String, dynamic>> attendees;
  final Map<String, dynamic>? creatorInfo;
  final VoidCallback onJoinLeave;
  final VoidCallback onShowSignupDialog;
  final VoidCallback onNavigateToChat;

  const EventActions({
    super.key,
    required this.event,
    required this.isCreator,
    required this.isPastEvent,
    required this.isGuest,
    required this.hasJoined,
    required this.attendees,
    required this.creatorInfo,
    required this.onJoinLeave,
    required this.onShowSignupDialog,
    required this.onNavigateToChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action buttons with modern styling
        Column(
          children: [
            if (!isCreator && !isPastEvent) ...[
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        hasJoined
                            ? [Colors.red.shade400, Colors.red.shade600]
                            : [Colors.teal.shade400, Colors.teal.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (hasJoined ? Colors.red : Colors.teal).withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isGuest ? onShowSignupDialog : onJoinLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasJoined ? Icons.exit_to_app : Icons.group_add,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isGuest
                            ? "Join Event"
                            : (hasJoined ? "Leave Event" : "Join Event"),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (isCreator || hasJoined) ...[
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onNavigateToChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Discussion",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${attendees.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),

        // Event status message
        if (!isCreator && isPastEvent && !hasJoined && !isGuest) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_filled,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Event has ended. You cannot join now.",
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Event statistics
        if (attendees.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade100, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.people,
                  label: 'Attendees',
                  value: attendees.length.toString(),
                  color: Colors.teal,
                ),
                Container(width: 1, height: 40, color: Colors.teal.shade200),
                _buildStatItem(
                  icon: isPastEvent ? Icons.history : Icons.upcoming,
                  label: isPastEvent ? 'Completed' : 'Upcoming',
                  value: isPastEvent ? 'Done' : 'Soon',
                  color: isPastEvent ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
