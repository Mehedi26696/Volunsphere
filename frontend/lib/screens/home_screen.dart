import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/event_model.dart';
import '../services/events_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import '../services/notification_listener_service.dart';
import '../services/missed_message_service.dart';

import 'all_events_screen.dart';
import 'create_event_screen.dart';
import 'my_events_screen.dart';
import 'joined_events_screen.dart';
import 'event_details_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'app_drawer.dart';
import 'community_feed_screen.dart';
import 'notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Event>> _futureEvents;
  Map<String, dynamic>? userStats;
  bool isStatsLoading = true;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _futureEvents = EventsService.getAllEvents();
    _checkIfGuest();
    _loadUserStats();
    _initializeNotificationService();
  }

  Future<void> _initializeNotificationService() async {
    if (!isGuest) {
      print('Initializing notification services...');
      await NotificationService.instance.initialize();
      await NotificationListenerService.instance.initialize();

      // Check for missed messages when the app starts
      await MissedMessageService.checkMissedMessages();

      // Add a small delay then print debug info
      Timer(const Duration(seconds: 2), () {
        NotificationListenerService.instance.printDebugInfo();
      });
    }
  }

  Future<void> _checkIfGuest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> _loadUserStats() async {
    if (isGuest) {
      setState(() => isStatsLoading = false);
      return;
    }

    setState(() => isStatsLoading = true);
    final stats = await UserService.getUserStats();
    setState(() {
      userStats = stats;
      isStatsLoading = false;
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AllEventsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CommunityNewsfeedScreen()),
        );
        break;
      case 3:
        if (!isGuest) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
        break;
      case 4:
        if (!isGuest) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        }
        break;
    }
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 120;
        return Container(
          padding: EdgeInsets.all(isSmall ? 12 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
                ),
                child: Icon(icon, size: isSmall ? 24 : 32, color: Colors.white),
              ),
              SizedBox(height: isSmall ? 8 : 12),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 18 : 24,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: isSmall ? 2 : 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                  fontSize: isSmall ? 11 : 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          hoverColor: Colors.white.withValues(alpha: 0.1),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final date = DateFormat.yMMMMd().format(start);
    final startTime = DateFormat.jm().format(start);
    final endTime = DateFormat.jm().format(end);
    return "$date\n$startTime - $endTime";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Purple App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 350;
                  return Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Builder(
                          builder:
                              (context) => IconButton(
                                onPressed:
                                    () => Scaffold.of(context).openDrawer(),
                                icon: const Icon(
                                  Icons.menu_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "VolunSphere",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 20 : 24,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      Consumer<NotificationService>(
                        builder: (context, notificationService, child) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => const NotificationScreen(),
                                        transitionDuration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionsBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              ),
                                            ),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  tooltip: "Notifications",
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                ),
                                if (notificationService.unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        notificationService.unreadCount > 9
                                            ? '9+'
                                            : notificationService.unreadCount
                                                .toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // Content
            Expanded(
              child: FutureBuilder<List<Event>>(
                future: _futureEvents,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7B2CBF,
                              ).withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7B2CBF),
                                    Color(0xFF9D4EDD),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Loading events...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF27264A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading events: ${snapshot.error}'),
                    );
                  }

                  final allEvents = snapshot.data ?? [];
                  final homeEvents = allEvents.take(3).toList();

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 400;
                        final horizontalPadding = isSmallScreen ? 16.0 : 20.0;

                        return ListView(
                          padding: EdgeInsets.all(horizontalPadding),
                          children: [
                            // Welcome Section
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 8.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome, Volunteer!",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: isSmallScreen ? 20 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF27264A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  const Text(
                                    "Make a difference in your community today.",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Color(0xFF626C7A),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: isSmallScreen ? 20 : 24),

                            // Stats Section
                            if (!isGuest)
                              isStatsLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF7B2CBF),
                                    ),
                                  )
                                  : LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isSmallScreen =
                                          constraints.maxWidth < 400;
                                      if (isSmallScreen) {
                                        // For small screens, display stats in a 2x2 grid with the 3rd item spanning full width
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildStatItem(
                                                    Icons.event_rounded,
                                                    "Events",
                                                    userStats?['events_joined']
                                                            ?.toString() ??
                                                        '0',
                                                    const Color(0xFF4CAF50),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildStatItem(
                                                    Icons.access_time_rounded,
                                                    "Hours",
                                                    userStats?['hours_volunteered']
                                                            ?.toString() ??
                                                        '0',
                                                    const Color(0xFF2196F3),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              width: double.infinity,
                                              constraints: const BoxConstraints(
                                                maxWidth: 200,
                                              ),
                                              child: _buildStatItem(
                                                Icons.star_rounded,
                                                "Avg. Rating",
                                                userStats?['average_rating']
                                                        ?.toStringAsFixed(1) ??
                                                    '0.0',
                                                const Color(0xFFFF9800),
                                              ),
                                            ),
                                          ],
                                        );
                                      } else {
                                        // For larger screens, keep the original row layout
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: _buildStatItem(
                                                Icons.event_rounded,
                                                "Events Joined",
                                                userStats?['events_joined']
                                                        ?.toString() ??
                                                    '0',
                                                const Color(0xFF4CAF50),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _buildStatItem(
                                                Icons.access_time_rounded,
                                                "Hours Volunteered",
                                                userStats?['hours_volunteered']
                                                        ?.toString() ??
                                                    '0',
                                                const Color(0xFF2196F3),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _buildStatItem(
                                                Icons.star_rounded,
                                                "Avg. Rating",
                                                userStats?['average_rating']
                                                        ?.toStringAsFixed(1) ??
                                                    '0.0',
                                                const Color(0xFFFF9800),
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),

                            const SizedBox(height: 24),

                            // Action Buttons
                            if (!isGuest) ...[
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isSmallScreen =
                                      constraints.maxWidth < 450;

                                  if (isSmallScreen) {
                                    // For small screens, stack buttons vertically
                                    return Column(
                                      children: [
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: _buildActionButton(
                                            icon: Icons.add_rounded,
                                            title: "Create Event",
                                            onPressed:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            const CreateEventScreen(),
                                                  ),
                                                ),
                                            gradientColors: [
                                              const Color(0xFFE040FB),
                                              const Color(0xFFFF80AB),
                                            ],
                                            isFullWidth: true,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: _buildActionButton(
                                            icon: Icons.event_note_rounded,
                                            title: "My Events",
                                            onPressed:
                                                () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) =>
                                                            const MyEventsScreen(),
                                                  ),
                                                ),
                                            gradientColors: [
                                              const Color(0xFF2196F3),
                                              const Color(0xFF64B5F6),
                                            ],
                                            isFullWidth: true,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // For larger screens, keep the original row layout
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: _buildActionButton(
                                              icon: Icons.add_rounded,
                                              title: "Create Event",
                                              onPressed:
                                                  () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              const CreateEventScreen(),
                                                    ),
                                                  ),
                                              gradientColors: [
                                                const Color(0xFFE040FB),
                                                const Color(0xFFFF80AB),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: _buildActionButton(
                                              icon: Icons.event_note_rounded,
                                              title: "My Events",
                                              onPressed:
                                                  () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              const MyEventsScreen(),
                                                    ),
                                                  ),
                                              gradientColors: [
                                                const Color(0xFF2196F3),
                                                const Color(0xFF64B5F6),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: _buildActionButton(
                                  icon: Icons.group_rounded,
                                  title: "Joined Events",
                                  onPressed:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const JoinedEventsScreen(),
                                        ),
                                      ),
                                  gradientColors: [
                                    const Color(0xFF4CAF50),
                                    const Color(0xFF81C784),
                                  ],
                                  isFullWidth: true,
                                ),
                              ),
                              const SizedBox(height: 28),
                            ],

                            // Events Section
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    "Volunteer Opportunities",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF27264A),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => const AllEventsScreen(),
                                        ),
                                      );
                                    },
                                    hoverColor: const Color(
                                      0xFF7B2CBF,
                                    ).withValues(alpha: 0.1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF7B2CBF,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF7B2CBF,
                                          ).withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "See All",
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              color: const Color(0xFF7B2CBF),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: const Color(0xFF7B2CBF),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Events List
                            if (allEvents.isEmpty)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF626C7A,
                                    ).withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF626C7A,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Icon(
                                        Icons.sentiment_dissatisfied_rounded,
                                        color: const Color(
                                          0xFF626C7A,
                                        ).withValues(alpha: 0.7),
                                        size: 48,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "No volunteer opportunities currently available.",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        color: Color(0xFF626C7A),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ...homeEvents.map(
                                (event) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF7B2CBF,
                                      ).withValues(alpha: 0.15),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF7B2CBF,
                                        ).withValues(alpha: 0.08),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => EventDetailsScreen(
                                                    eventId: event.id,
                                                  ),
                                            ),
                                          ),
                                      hoverColor: const Color(
                                        0xFF7B2CBF,
                                      ).withValues(alpha: 0.05),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isSmallScreen =
                                              constraints.maxWidth < 400;
                                          return Padding(
                                            padding: EdgeInsets.all(
                                              isSmallScreen ? 16 : 20,
                                            ),
                                            child:
                                                isSmallScreen
                                                    ? Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // Event title and icon row
                                                        Row(
                                                          children: [
                                                            Container(
                                                              width: 50,
                                                              height: 50,
                                                              decoration: BoxDecoration(
                                                                gradient: const LinearGradient(
                                                                  colors: [
                                                                    Color(
                                                                      0xFF7B2CBF,
                                                                    ),
                                                                    Color(
                                                                      0xFF9D4EDD,
                                                                    ),
                                                                  ],
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      15,
                                                                    ),
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .event_rounded,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                size: 26,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 12,
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    event.title,
                                                                    style: const TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      fontSize:
                                                                          16,
                                                                      color: Color(
                                                                        0xFF27264A,
                                                                      ),
                                                                      letterSpacing:
                                                                          -0.5,
                                                                    ),
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 4,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      Container(
                                                                        padding:
                                                                            const EdgeInsets.all(
                                                                              4,
                                                                            ),
                                                                        decoration: BoxDecoration(
                                                                          color: const Color(
                                                                            0xFF4CAF50,
                                                                          ).withValues(
                                                                            alpha:
                                                                                0.1,
                                                                          ),
                                                                          borderRadius:
                                                                              BorderRadius.circular(
                                                                                6,
                                                                              ),
                                                                        ),
                                                                        child: Icon(
                                                                          Icons
                                                                              .location_on_rounded,
                                                                          size:
                                                                              14,
                                                                          color: const Color(
                                                                            0xFF4CAF50,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            6,
                                                                      ),
                                                                      Expanded(
                                                                        child: Text(
                                                                          event.location ??
                                                                              "No location",
                                                                          style: const TextStyle(
                                                                            fontFamily:
                                                                                'Poppins',
                                                                            fontSize:
                                                                                12,
                                                                            color: Color(
                                                                              0xFF626C7A,
                                                                            ),
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            letterSpacing:
                                                                                -0.2,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        // Description
                                                        Text(
                                                          event.description ??
                                                              "No description",
                                                          style:
                                                              const TextStyle(
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF626C7A,
                                                                ),
                                                                letterSpacing:
                                                                    -0.2,
                                                              ),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        // Time and button row
                                                        Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFF2196F3,
                                                                    ).withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .access_time_rounded,
                                                                size: 14,
                                                                color:
                                                                    const Color(
                                                                      0xFF2196F3,
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                _formatDateRange(
                                                                  event
                                                                      .startDatetime,
                                                                  event
                                                                      .endDatetime,
                                                                ),
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontSize: 11,
                                                                  color: Color(
                                                                    0xFF626C7A,
                                                                  ),
                                                                  letterSpacing:
                                                                      -0.2,
                                                                ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                gradient: const LinearGradient(
                                                                  colors: [
                                                                    Color(
                                                                      0xFF7B2CBF,
                                                                    ),
                                                                    Color(
                                                                      0xFF9D4EDD,
                                                                    ),
                                                                  ],
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                              child: ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  shadowColor:
                                                                      Colors
                                                                          .transparent,
                                                                  elevation: 0,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            12,
                                                                        vertical:
                                                                            8,
                                                                      ),
                                                                ),
                                                                onPressed:
                                                                    () => Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (
                                                                              _,
                                                                            ) => EventDetailsScreen(
                                                                              eventId:
                                                                                  event.id,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                child: const Text(
                                                                  "Details",
                                                                  style: TextStyle(
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    )
                                                    : Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Container(
                                                          width: 60,
                                                          height: 60,
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                const LinearGradient(
                                                                  colors: [
                                                                    Color(
                                                                      0xFF7B2CBF,
                                                                    ),
                                                                    Color(
                                                                      0xFF9D4EDD,
                                                                    ),
                                                                  ],
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  18,
                                                                ),
                                                          ),
                                                          child: const Icon(
                                                            Icons.event_rounded,
                                                            color: Colors.white,
                                                            size: 32,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 16,
                                                        ),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                event.title,
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 17,
                                                                  color: Color(
                                                                    0xFF27264A,
                                                                  ),
                                                                  letterSpacing:
                                                                      -0.5,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          6,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFF4CAF50,
                                                                      ).withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .location_on_rounded,
                                                                      size: 16,
                                                                      color: const Color(
                                                                        0xFF4CAF50,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Expanded(
                                                                    child: Text(
                                                                      event.location ??
                                                                          "No location",
                                                                      style: const TextStyle(
                                                                        fontFamily:
                                                                            'Poppins',
                                                                        fontSize:
                                                                            13,
                                                                        color: Color(
                                                                          0xFF626C7A,
                                                                        ),
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                        letterSpacing:
                                                                            -0.2,
                                                                      ),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                height: 6,
                                                              ),
                                                              Text(
                                                                event.description ??
                                                                    "No description",
                                                                style: const TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                    0xFF626C7A,
                                                                  ),
                                                                  letterSpacing:
                                                                      -0.2,
                                                                ),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          6,
                                                                        ),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(
                                                                        0xFF2196F3,
                                                                      ).withValues(
                                                                        alpha:
                                                                            0.1,
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .access_time_rounded,
                                                                      size: 15,
                                                                      color: const Color(
                                                                        0xFF2196F3,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    _formatDateRange(
                                                                      event
                                                                          .startDatetime,
                                                                      event
                                                                          .endDatetime,
                                                                    ),
                                                                    style: const TextStyle(
                                                                      fontFamily:
                                                                          'Poppins',
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                        0xFF626C7A,
                                                                      ),
                                                                      letterSpacing:
                                                                          -0.2,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                const LinearGradient(
                                                                  colors: [
                                                                    Color(
                                                                      0xFF7B2CBF,
                                                                    ),
                                                                    Color(
                                                                      0xFF9D4EDD,
                                                                    ),
                                                                  ],
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: ElevatedButton(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              shadowColor:
                                                                  Colors
                                                                      .transparent,
                                                              elevation: 0,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical:
                                                                        10,
                                                                  ),
                                                            ),
                                                            onPressed:
                                                                () => Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (
                                                                          _,
                                                                        ) => EventDetailsScreen(
                                                                          eventId:
                                                                              event.id,
                                                                        ),
                                                                  ),
                                                                ),
                                                            child: const Text(
                                                              "Details",
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 400;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2CBF).withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              selectedItemColor: const Color(0xFF7B2CBF),
              unselectedItemColor: const Color(
                0xFF626C7A,
              ).withValues(alpha: 0.7),
              backgroundColor: Colors.white,
              currentIndex: _selectedIndex,
              onTap: _onNavTap,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              selectedLabelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 10 : 12,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: isSmallScreen ? 10 : 12,
              ),
              iconSize: isSmallScreen ? 22 : 24,
              items:
                  isGuest
                      ? const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home_rounded),
                          label: "Home",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.event_rounded),
                          label: "Events",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.forum_rounded),
                          label: "Community",
                        ),
                      ]
                      : const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home_rounded),
                          label: "Home",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.event_rounded),
                          label: "Events",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.forum_rounded),
                          label: "Community",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person_rounded),
                          label: "Profile",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.settings_rounded),
                          label: "Settings",
                        ),
                      ],
            ),
          );
        },
      ),
      // Debug FloatingActionButton removed
    );
  }
}
