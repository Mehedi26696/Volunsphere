import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_model.dart';
import '../services/events_service.dart';
import '../services/auth_service.dart';
import 'event_details_screen.dart';

class JoinedEventsScreen extends StatefulWidget {
  const JoinedEventsScreen({super.key});

  @override
  State<JoinedEventsScreen> createState() => _JoinedEventsScreenState();
}

class _JoinedEventsScreenState extends State<JoinedEventsScreen> {
  late Future<List<Event>> _futureJoinedEvents;

  @override
  void initState() {
    super.initState();
    _futureJoinedEvents = _loadJoinedEvents();
  }

  Future<List<Event>> _loadJoinedEvents() async {
    final token = await AuthService.getToken();
    final allEvents = await EventsService.getAllEvents();
    final userId = (await AuthService.getTokenData())?['sub'];
    final joined = <Event>[];

    for (final event in allEvents) {
      final attendees = await EventsService.getEventAttendees(event.id);
      if (attendees.any((a) => a['id'] == userId)) {
        joined.add(event);
      }
    }

    return joined;
  }

  String _formatDateTimeRange(DateTime start, DateTime end) {
    final date = DateFormat.yMMMMd().format(start);
    final startTime = DateFormat.jm().format(start);
    final endTime = DateFormat.jm().format(end);
    return "$date\n$startTime - $endTime";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text("Joined Events"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.teal[800],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: Colors.teal[800]),
      ),
      body: FutureBuilder<List<Event>>(
        future: _futureJoinedEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.teal));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent),
              ),
            );
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.teal[100]),
                  const SizedBox(height: 16),
                  Text(
                    "You haven't joined any events yet.",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: events.length,
            itemBuilder: (context, i) {
              final event = events[i];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.07),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    splashColor: Colors.teal.withOpacity(0.08),
                    highlightColor: Colors.teal.withOpacity(0.03),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailsScreen(eventId: event.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.teal[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event,
                              color: Colors.teal[400],
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[900],
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 18, color: Colors.teal[300]),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        event.location ?? 'No location',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.calendar_today, size: 18, color: Colors.teal[300]),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _formatDateTimeRange(event.startDatetime, event.endDatetime),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.teal[200], size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
