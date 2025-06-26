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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0, top: 16.0),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: Colors.teal, size: 22),
          if (icon != null) const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGuest) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Attendees", icon: Icons.people_alt),
        TextField(
          decoration: InputDecoration(
            labelText: 'Search Attendees',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: widget.onFilterAttendees,
        ),
        const SizedBox(height: 10),
        widget.filteredAttendees.isEmpty
            ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "No attendees found",
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.filteredAttendees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final attendee = widget.filteredAttendees[index];
                final isCreatorUser =
                    attendee['id'].toString() == widget.eventCreatorId;
                final userId = attendee['id'].toString();

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            backgroundImage:
                                attendee['profile_image_url'] != null
                                    ? NetworkImage(
                                      attendee['profile_image_url'],
                                    )
                                    : null,
                            child:
                                attendee['profile_image_url'] == null
                                    ? const Icon(
                                      Icons.person,
                                      color: Colors.teal,
                                    )
                                    : null,
                          ),
                          title: Text(
                            attendee['username'] ?? 'Unknown',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                          subtitle: Text(
                            attendee['email'] ?? '',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.teal.shade700,
                            ),
                          ),
                          trailing:
                              isCreatorUser
                                  ? Chip(
                                    label: const Text(
                                      "Creator",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.teal.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  )
                                  : null,
                          onTap: () => widget.onNavigateToProfile(attendee),
                        ),
                        if (widget.isCreator &&
                            widget.isPastEvent &&
                            !isCreatorUser)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Rating:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StarRating(
                                      rating: widget.ratings[userId] ?? 0,
                                      onRatingChanged: (newRating) {
                                        widget.onRatingChanged(
                                          userId,
                                          newRating,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      "Work Hours:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: TextFormField(
                                        initialValue:
                                            (widget.workTimes[userId] ?? 0.0)
                                                .toStringAsFixed(1),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                          isDense: true,
                                        ),
                                        onChanged: (val) {
                                          final parsed =
                                              double.tryParse(val) ?? 0.0;
                                          widget.onWorkTimeChanged(
                                            userId,
                                            parsed,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text("Submit"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade700,
                                      foregroundColor: Colors.white,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                    ),
                                    onPressed: () async {
                                      final rating =
                                          widget.ratings[userId] ?? 0;
                                      final workTime =
                                          widget.workTimes[userId] ?? 0.0;
                                      await widget.onUpdateResponse(
                                        userId,
                                        rating,
                                        workTime,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ],
    );
  }
}
