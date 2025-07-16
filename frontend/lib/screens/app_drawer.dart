import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/all_events_screen.dart';
import '../screens/my_events_screen.dart';
import '../screens/joined_events_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/login_screen.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../screens/theme_provider.dart';
import 'community_feed_screen.dart';
import 'leaderboard_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? _profileData;
  bool _loading = true;
  String? _error;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _checkIfGuest();
  }

  Future<void> _checkIfGuest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profileService = ProfileService();
      final profile = await profileService.getUserProfile();

      if (mounted) {
        setState(() {
          _profileData = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile';
          _loading = false;
        });
      }
    }
  }

  void _navigateAndCloseDrawer(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showSignupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sign Up Required"),
          content: const Text(
            "You need to sign up to access the Community Newsfeed feature.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/signup');
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final profileImageUrl = _profileData?['profile_image_url'];
    final userName =
        _profileData?['username'] ?? _profileData?['first_name'] ?? 'Guest';
    final userEmail = _profileData?['email'];

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await _checkIfGuest();
            await _fetchProfile();
          },
          color: const Color(0xFF7B2CBF),
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _loading
                  ? Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                  : Container(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    profileImageUrl != null &&
                                            profileImageUrl.isNotEmpty
                                        ? NetworkImage(profileImageUrl)
                                        : const AssetImage(
                                              "assets/images/default_profile.jpg",
                                            )
                                            as ImageProvider,
                                child:
                                    profileImageUrl == null ||
                                            profileImageUrl.isEmpty
                                        ? Icon(
                                          Icons.person_rounded,
                                          size: 40,
                                          color: const Color(0xFF7B2CBF),
                                        )
                                        : null,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  await _checkIfGuest();
                                  await _fetchProfile();
                                },
                                tooltip: 'Refresh Profile',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (userEmail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

              const SizedBox(height: 8),

              _buildDrawerItem(
                icon: Icons.home_rounded,
                title: "Home",
                onTap: () => Navigator.pop(context),
                color: const Color(0xFF4CAF50),
              ),

              _buildDrawerItem(
                icon: Icons.event_rounded,
                title: "All Events",
                onTap: () => _navigateAndCloseDrawer(const AllEventsScreen()),
                color: const Color(0xFF2196F3),
              ),

              if (!isGuest) ...[
                _buildDrawerItem(
                  icon: Icons.event_note_rounded,
                  title: "My Events",
                  onTap: () => _navigateAndCloseDrawer(const MyEventsScreen()),
                  color: const Color(0xFFFF9800),
                ),
                _buildDrawerItem(
                  icon: Icons.group_rounded,
                  title: "Joined Events",
                  onTap:
                      () => _navigateAndCloseDrawer(const JoinedEventsScreen()),
                  color: const Color(0xFFE91E63),
                ),
              ],

              _buildDrawerItem(
                icon: Icons.forum_rounded,
                title: "Community Newsfeed",
                onTap: () {
                  if (isGuest) {
                    Navigator.pop(context);
                    _showSignupDialog();
                  } else {
                    _navigateAndCloseDrawer(const CommunityNewsfeedScreen());
                  }
                },
                color: const Color(0xFF9C27B0),
              ),

              _buildDrawerItem(
                icon: Icons.leaderboard_rounded,
                title: "Leaderboard",
                onTap: () => _navigateAndCloseDrawer(const LeaderboardScreen()),
                color: const Color(0xFF00BCD4),
              ),

              if (!isGuest)
                _buildDrawerItem(
                  icon: Icons.smart_toy_rounded,
                  title: "Database Assistant",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/chatbot');
                  },
                  color: const Color(0xFF3F51B5),
                ),

              if (!isGuest)
                _buildDrawerItem(
                  icon: Icons.person_rounded,
                  title: "Profile",
                  onTap: () => _navigateAndCloseDrawer(const ProfileScreen()),
                  color: const Color(0xFF795548),
                ),

              if (!isGuest)
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: "Settings",
                  onTap: () => _navigateAndCloseDrawer(const SettingsScreen()),
                  color: const Color(0xFF607D8B),
                ),

              if (isGuest)
                _buildDrawerItem(
                  icon: Icons.person_add_rounded,
                  title: "Sign Up",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/signup');
                  },
                  color: const Color(0xFF4CAF50),
                ),

              const SizedBox(height: 8),

              // ...existing code...
              _buildDrawerItem(
                icon: Icons.logout_rounded,
                title: "Logout",
                onTap: () async {
                  await AuthService().logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                color: Colors.red,
                isLogout: true,
              ),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isLogout
                  ? Colors.red.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          hoverColor:
              isLogout
                  ? Colors.red.withValues(alpha: 0.1)
                  : color.withValues(alpha: 0.1),
          splashColor:
              isLogout
                  ? Colors.red.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.2),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isLogout
                        ? Colors.red.withValues(alpha: 0.1)
                        : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isLogout ? Colors.red : color, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: isLogout ? Colors.red : const Color(0xFF27264A),
                letterSpacing: -0.3,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
          ),
        ),
      ),
    );
  }
}
