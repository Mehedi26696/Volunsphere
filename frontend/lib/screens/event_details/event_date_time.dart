import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';

class EventDateTime extends StatelessWidget {
  final Event event;

  const EventDateTime({super.key, required this.event});

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.schedule_rounded,
              color: const Color(0xFF9C27B0),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF27264A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'EEEE, MMMM d, y',
    ).format(event.startDatetime);
    final formattedStartTime = DateFormat.jm().format(event.startDatetime);
    final formattedEndTime = DateFormat.jm().format(event.endDatetime);

    final duration = event.endDatetime.difference(event.startDatetime);
    final durationText =
        duration.inHours > 0
            ? '${duration.inHours}h ${duration.inMinutes % 60}m'
            : '${duration.inMinutes}m';

    final isPastEvent = DateTime.now().isAfter(event.endDatetime);
    final isOngoing =
        DateTime.now().isAfter(event.startDatetime) &&
        DateTime.now().isBefore(event.endDatetime);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            context,
            "When & Duration",
            icon: Icons.schedule_rounded,
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF27264A),
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Event status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPastEvent
                                ? [
                                    const Color(0xFF626C7A).withValues(alpha: 0.1),
                                    const Color(0xFF626C7A).withValues(alpha: 0.05),
                                  ]
                                : isOngoing
                                ? [
                                    const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                    const Color(0xFF4CAF50).withValues(alpha: 0.05),
                                  ]
                                : [
                                    const Color(0xFF2196F3).withValues(alpha: 0.1),
                                    const Color(0xFF2196F3).withValues(alpha: 0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPastEvent
                                ? const Color(0xFF626C7A).withValues(alpha: 0.3)
                                : isOngoing
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                                : const Color(0xFF2196F3).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPastEvent
                                  ? Icons.check_circle_rounded
                                  : isOngoing
                                  ? Icons.play_circle_rounded
                                  : Icons.upcoming_rounded,
                              size: 16,
                              color: isPastEvent
                                  ? const Color(0xFF626C7A)
                                  : isOngoing
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF2196F3),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isPastEvent
                                  ? 'Ended'
                                  : isOngoing
                                  ? 'Live'
                                  : 'Upcoming',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isPastEvent
                                    ? const Color(0xFF626C7A)
                                    : isOngoing
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9C27B0).withValues(alpha: 0.1),
                        const Color(0xFF9C27B0).withValues(alpha: 0.3),
                        const Color(0xFF9C27B0).withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),

                // Time section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Start time
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Start Time',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedStartTime,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Duration
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE65100).withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.timelapse_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Duration',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              durationText,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // End time
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade400, Colors.red.shade300],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.stop_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'End Time',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedEndTime,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
