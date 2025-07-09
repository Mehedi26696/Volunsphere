import 'package:flutter/material.dart';
import '../star_rating.dart';

class EventAttendees extends StatefulWidget {
  final List<Map<String, dynamic>> attendees;
  final List<Map<String, dynamic>> filteredAttendees;
  final String searchQuery;
  final bool isGuest;
  final bool isCreator;
  final bool isPastEvent;
  final String eventCreatorId;
  final Map<String, int> ratings;
  final Map<String, double> workTimes;
  final Map<String, bool> editedResponses;
  final Function(String) onFilterAttendees;
  final Function(Map<String, dynamic>) onNavigateToProfile;
  final Function(String, int, double) onUpdateResponse;
  final Function(String, int) onRatingChanged;
  final Function(String, double) onWorkTimeChanged;

  const EventAttendees({
    super.key,
    required this.attendees,
    required this.filteredAttendees,
    required this.searchQuery,
    required this.isGuest,
    required this.isCreator,
    required this.isPastEvent,
    required this.eventCreatorId,
    required this.ratings,
    required this.workTimes,
    required this.editedResponses,
    required this.onFilterAttendees,
    required this.onNavigateToProfile,
    required this.onUpdateResponse,
    required this.onRatingChanged,
    required this.onWorkTimeChanged,
  });

  @override
  State<EventAttendees> createState() => _EventAttendeesState();
}

class _EventAttendeesState extends State<EventAttendees> {
  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.people_rounded,
              color: const Color(0xFF2196F3),
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
    if (widget.isGuest) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Attendees", icon: Icons.people_rounded),
          
          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Color(0xFF27264A),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                labelText: 'Search Attendees',
                labelStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF626C7A),
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: const Color(0xFF2196F3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: widget.onFilterAttendees,
            ),
          ),
          
          const SizedBox(height: 16),
          
          widget.filteredAttendees.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF626C7A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: const Color(0xFF626C7A).withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No attendees found",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.filteredAttendees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final attendee = widget.filteredAttendees[index];
                    final isCreatorUser = attendee['id'].toString() == widget.eventCreatorId;
                    final userId = attendee['id'].toString();

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => widget.onNavigateToProfile(attendee),
                              hoverColor: const Color(0xFF2196F3).withValues(alpha: 0.05),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.white,
                                        backgroundImage: attendee['profile_image_url'] != null
                                            ? NetworkImage(attendee['profile_image_url'])
                                            : null,
                                        child: attendee['profile_image_url'] == null
                                            ? const Icon(
                                                Icons.person_rounded,
                                                color: Color(0xFF2196F3),
                                                size: 24,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            attendee['username'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Color(0xFF27264A),
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            attendee['email'] ?? '',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 13,
                                              color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCreatorUser)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          "Creator",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          if (widget.isCreator && widget.isPastEvent && !isCreatorUser) ...[
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Rating:",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF27264A),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      StarRating(
                                        rating: widget.ratings[userId] ?? 0,
                                        onRatingChanged: (newRating) {
                                          widget.onRatingChanged(userId, newRating);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text(
                                        "Work Hours:",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF27264A),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextFormField(
                                          initialValue: (widget.workTimes[userId] ?? 0.0).toStringAsFixed(1),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            color: Color(0xFF27264A),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            isDense: true,
                                          ),
                                          onChanged: (val) {
                                            final parsed = double.tryParse(val) ?? 0.0;
                                            widget.onWorkTimeChanged(userId, parsed);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.check_rounded, size: 18),
                                        label: const Text("Submit"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        onPressed: () async {
                                          final rating = widget.ratings[userId] ?? 0;
                                          final workTime = widget.workTimes[userId] ?? 0.0;
                                          await widget.onUpdateResponse(userId, rating, workTime);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
