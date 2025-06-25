import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';
import '../services/events_service.dart';
import '../services/auth_service.dart';
import 'edit_event_screen.dart';
import 'user_profile_screen.dart';
import 'star_rating.dart';
import 'chat_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  Event? event;
  String? currentUserId;
  bool isLoading = true;
  bool hasJoined = false;
  bool isGuest = false;
  List<Map<String, dynamic>> attendees = [];
  List<Map<String, dynamic>> filteredAttendees = [];
  String searchQuery = "";

  Map<String, dynamic>? creatorInfo;
  bool isLoadingCreator = true;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  Map<String, int> _ratings = {};
  Map<String, double> _workTimes = {};
  Map<String, bool> _editedResponses = {};

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _checkIfGuest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> _loadEvent() async {
    setState(() {
      isLoading = true;
      isLoadingCreator = true;
    });

    try {
       
      await _checkIfGuest();

      final tokenData = await AuthService.getTokenData();
      final fetchedEvent = await EventsService.getEventById(widget.eventId);
      if (fetchedEvent == null) throw Exception("Event not found");

      final fetchedCreator = await EventsService.getUserById(
        fetchedEvent.creatorId.toString(),
      );

      final fetchedAttendees = await EventsService.getEventAttendees(
        widget.eventId,
      );
      final uid = tokenData?['sub'] as String?;
      final joined = fetchedAttendees.any((a) => a['id'] == uid);

      for (var attendee in fetchedAttendees) {
        _ratings[attendee['id']] = attendee['rating'] ?? 0;
        _workTimes[attendee['id']] =
            (attendee['work_time_hours'] ?? 0.0).toDouble();
      }

      Set<Marker> markers = {};
      if (fetchedEvent.latitude != null && fetchedEvent.longitude != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('event_location'),
            position: LatLng(fetchedEvent.latitude!, fetchedEvent.longitude!),
          ),
        );
      }

      setState(() {
        currentUserId = uid;
        event = fetchedEvent;
        creatorInfo = fetchedCreator;
        attendees = fetchedAttendees;
        filteredAttendees = fetchedAttendees;
        hasJoined = joined;
        _markers = markers;
        isLoading = false;
        isLoadingCreator = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingCreator = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load event: $e')));
      }
    }
  }

  void _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Delete Event"),
            content: const Text("Are you sure you want to delete this event?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final success = await EventsService.deleteEvent(widget.eventId);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Event deleted.")));
      }
    }
  }

  void _editEvent() async {
    if (event == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditEventScreen(event: event!)),
    );

    if (updated == true) {
      _loadEvent();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event updated!')));
      }
    }
  }

  void _joinOrLeaveEvent() async {
    try {
      bool success;
      if (hasJoined) {
        success = await EventsService.leaveEvent(widget.eventId);
      } else {
        success = await EventsService.joinEvent(widget.eventId);
      }

      if (success) {
        await _loadEvent();
      } else {
        throw Exception('Failed to ${hasJoined ? "leave" : "join"} event');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showSignupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sign Up Required"),
          content: const Text("You need to sign up to join events."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text("Sign Up"),
            ),
          ],
        );
      },
    );
  }

  void _filterAttendees(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredAttendees =
          attendees
              .where(
                (a) =>
                    (a['username'] as String).toLowerCase().contains(
                      searchQuery,
                    ) ||
                    (a['email'] as String).toLowerCase().contains(searchQuery),
              )
              .toList();
    });
  }

  void _navigateToUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserProfileScreen(user: user)),
    );
  }

  Future<void> _updateResponse(
    String userId,
    int rating,
    double workTime,
  ) async {
    try {
      final success = await EventsService.updateEventResponse(
        eventId: widget.eventId,
        userId: userId,
        rating: rating,
        workTimeHours: workTime,
      );

      if (success && mounted) {
        setState(() {
          _ratings[userId] = rating;
          _workTimes[userId] = workTime;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Response updated')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update response')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating response: $e')));
    }
  }

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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text("Event Details"),
        ),
        body: const Center(child: Text("Event not found")),
      );
    }

    final isCreator = currentUserId == event!.creatorId.toString();
    final formattedDate = DateFormat.yMMMMd().format(event!.startDatetime);
    final formattedStartTime = DateFormat.jm().format(event!.startDatetime);
    final formattedEndTime = DateFormat.jm().format(event!.endDatetime);
    final isPastEvent = DateTime.now().isAfter(event!.endDatetime);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal.shade800,
        title: Text(
          event!.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions:
            isCreator
                ? [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: _editEvent,
                    tooltip: 'Edit Event',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: _deleteEvent,
                    tooltip: 'Delete Event',
                  ),
                ]
                : [],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 
                if (event!.imageUrls != null && event!.imageUrls!.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: event!.imageUrls!.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final url = event!.imageUrls![index];
                          return Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(18),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                url,
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 180,
                                    height: 180,
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      width: 180,
                                      height: 180,
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (event!.imageUrls != null && event!.imageUrls!.isNotEmpty)
                  const SizedBox(height: 18),

                
                if (!isGuest)
                  _buildSectionTitle("Organizer", icon: Icons.person),
                if (!isGuest && isLoadingCreator)
                  const Center(child: CircularProgressIndicator())
                else if (!isGuest && creatorInfo != null)
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage:
                            creatorInfo!['profile_image_url'] != null
                                ? NetworkImage(
                                  creatorInfo!['profile_image_url'],
                                )
                                : null,
                        child:
                            creatorInfo!['profile_image_url'] == null
                                ? const Icon(
                                  Icons.person,
                                  color: Colors.teal,
                                  size: 28,
                                )
                                : null,
                      ),
                      title: Text(
                        creatorInfo!['username'] ?? 'Creator',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      subtitle: Text(
                        creatorInfo!['email'] ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.teal.shade700,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.teal,
                        ),
                        onPressed: () => _navigateToUserProfile(creatorInfo!),
                        tooltip: "View Profile",
                      ),
                    ),
                  ),

            
                _buildSectionTitle("Location", icon: Icons.location_on),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, color: Colors.teal, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event!.location ?? 'No location specified',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_markers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 180,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _markers.first.position,
                            zoom: 15,
                          ),
                          markers: _markers,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                        ),
                      ),
                    ),
                  ),

                 
                _buildSectionTitle("Date & Time", icon: Icons.access_time),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.teal,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$formattedDate\n$formattedStartTime - $formattedEndTime',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      if (!isCreator && !isPastEvent)
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                isGuest ? _showSignupDialog : _joinOrLeaveEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  hasJoined ? Colors.redAccent : Colors.teal,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text(
                              isGuest
                                  ? "Join Event"
                                  : (hasJoined ? "Leave Event" : "Join Event"),
                            ),
                          ),
                        ),
                      if ((isCreator || hasJoined) &&
                          (!isCreator || isPastEvent))
                        const SizedBox(width: 12),
                      if (isCreator || hasJoined)
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text("Discussion"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ChatScreen(
                                        eventId: event!.id.toString(),
                                        attendees: attendees,
                                        creator: creatorInfo!,
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (!isCreator && isPastEvent && !hasJoined && !isGuest)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Event has ended. You cannot join now.",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),

                 
                if (!isGuest)
                  _buildSectionTitle("Attendees", icon: Icons.people_alt),
                if (!isGuest)
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Attendees',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: _filterAttendees,
                  ),
                if (!isGuest) const SizedBox(height: 10),
                if (!isGuest)
                  filteredAttendees.isEmpty
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
                        itemCount: filteredAttendees.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final attendee = filteredAttendees[index];
                          final isCreatorUser =
                              attendee['id'].toString() ==
                              event!.creatorId.toString();
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
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.teal.shade700,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                            )
                                            : null,
                                    onTap:
                                        () => _navigateToUserProfile(attendee),
                                  ),

                                  
                                  if (isCreator &&
                                      isPastEvent &&
                                      !isCreatorUser)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                rating: _ratings[userId] ?? 0,
                                                onRatingChanged: (newRating) {
                                                  setState(() {
                                                    _ratings[userId] =
                                                        newRating;
                                                    _editedResponses[userId] =
                                                        true;
                                                  });
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
                                                      (_workTimes[userId] ??
                                                              0.0)
                                                          .toStringAsFixed(1),
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
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
                                                        double.tryParse(val) ??
                                                        0.0;
                                                    setState(() {
                                                      _workTimes[userId] =
                                                          parsed;
                                                      _editedResponses[userId] =
                                                          true;
                                                    });
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
                                                backgroundColor:
                                                    Colors.teal.shade700,
                                                foregroundColor: Colors.white,
                                                elevation: 1,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 18,
                                                      vertical: 10,
                                                    ),
                                              ),
                                              onPressed: () async {
                                                final rating =
                                                    _ratings[userId] ?? 0;
                                                final workTime =
                                                    _workTimes[userId] ?? 0.0;
                                                await _updateResponse(
                                                  userId,
                                                  rating,
                                                  workTime,
                                                );
                                                setState(() {
                                                  _editedResponses[userId] =
                                                      false;
                                                });
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
