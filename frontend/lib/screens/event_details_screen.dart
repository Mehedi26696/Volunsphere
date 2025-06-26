import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_model.dart';
import '../services/events_service.dart';
import '../services/auth_service.dart';
import 'edit_event_screen.dart';
import 'user_profile_screen.dart';
import 'chat_screen.dart';

import 'event_details/event_header.dart';
import 'event_details/event_images.dart';
import 'event_details/event_description.dart';
import 'event_details/event_organizer.dart';
import 'event_details/event_location.dart';
import 'event_details/event_date_time.dart';
import 'event_details/event_actions.dart';
import 'event_details/event_attendees.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({super.key, required this.eventId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with SingleTickerProviderStateMixin {
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

  Set<Marker> _markers = {};

  Map<String, int> _ratings = {};
  Map<String, double> _workTimes = {};
  Map<String, bool> _editedResponses = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadEvent();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

      _animationController.forward();
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
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Delete Event",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
            content: const Text(
              "Are you sure you want to delete this event? This action cannot be undone and all attendees will be notified.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Delete",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade300, Colors.teal.shade400],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Sign Up Required",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          content: const Text(
            "Join our community to participate in events, connect with like-minded volunteers, and make a difference!",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4A5568),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Maybe Later",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              child: const Text(
                "Sign Up",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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

  void _navigateToChat() {
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
          _editedResponses[userId] = false;
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

  void _onRatingChanged(String userId, int newRating) {
    setState(() {
      _ratings[userId] = newRating;
      _editedResponses[userId] = true;
    });
  }

  void _onWorkTimeChanged(String userId, double newWorkTime) {
    setState(() {
      _workTimes[userId] = newWorkTime;
      _editedResponses[userId] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F9FA), Color(0xFFF0F8FF)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.teal,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Loading event details...",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (event == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: const Text(
            "Event Details",
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Event not found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isCreator = currentUserId == event!.creatorId.toString();
    final isPastEvent = DateTime.now().isAfter(event!.endDatetime);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: EventHeader(
        event: event!,
        isCreator: isCreator,
        onEdit: _editEvent,
        onDelete: _deleteEvent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFF0F8FF)],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EventImages(event: event!),

                        const SizedBox(height: 16),

                        EventDescription(event: event!),

                        const SizedBox(height: 20),

                        EventOrganizer(
                          creatorInfo: creatorInfo,
                          isLoadingCreator: isLoadingCreator,
                          isGuest: isGuest,
                          onNavigateToProfile: _navigateToUserProfile,
                        ),

                        const SizedBox(height: 20),

                        EventLocation(event: event!, markers: _markers),

                        const SizedBox(height: 20),

                        EventDateTime(event: event!),

                        const SizedBox(height: 20),

                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Color(0xFFF8F9FA)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: EventActions(
                              event: event!,
                              isCreator: isCreator,
                              isPastEvent: isPastEvent,
                              isGuest: isGuest,
                              hasJoined: hasJoined,
                              attendees: attendees,
                              creatorInfo: creatorInfo,
                              onJoinLeave: _joinOrLeaveEvent,
                              onShowSignupDialog: _showSignupDialog,
                              onNavigateToChat: _navigateToChat,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        EventAttendees(
                          attendees: attendees,
                          filteredAttendees: filteredAttendees,
                          searchQuery: searchQuery,
                          isGuest: isGuest,
                          isCreator: isCreator,
                          isPastEvent: isPastEvent,
                          eventCreatorId: event!.creatorId.toString(),
                          ratings: _ratings,
                          workTimes: _workTimes,
                          editedResponses: _editedResponses,
                          onFilterAttendees: _filterAttendees,
                          onNavigateToProfile: _navigateToUserProfile,
                          onUpdateResponse: _updateResponse,
                          onRatingChanged: _onRatingChanged,
                          onWorkTimeChanged: _onWorkTimeChanged,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
