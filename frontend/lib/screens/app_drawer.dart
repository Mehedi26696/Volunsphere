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
      child: RefreshIndicator(
        onRefresh: () async {
          await _checkIfGuest();
          await _fetchProfile();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _loading
                ? DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.teal),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
                : UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.teal),
                  accountName: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: userEmail != null ? Text(userEmail) : null,
                  currentAccountPicture: CircleAvatar(
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : const AssetImage(
                                  "assets/images/default_profile.jpg",
                                )
                                as ImageProvider,
                    backgroundColor: Colors.white,
                  ),
                  otherAccountsPictures: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () async {
                        await _checkIfGuest();
                        await _fetchProfile();
                      },
                      tooltip: 'Refresh Profile',
                    ),
                  ],
                ),

            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("All Events"),
              onTap: () => _navigateAndCloseDrawer(const AllEventsScreen()),
            ),

            if (!isGuest) ...[
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text("My Events"),
                onTap: () => _navigateAndCloseDrawer(const MyEventsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text("Joined Events"),
                onTap:
                    () => _navigateAndCloseDrawer(const JoinedEventsScreen()),
              ),
            ],

            ListTile(
              leading: const Icon(Icons.forum),
              title: const Text("Community Newsfeed"),
              onTap: () {
                if (isGuest) {
                  Navigator.pop(context);
                  _showSignupDialog();
                } else {
                  _navigateAndCloseDrawer(const CommunityNewsfeedScreen());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.leaderboard),
              title: const Text("Leaderboard"),
              onTap: () => _navigateAndCloseDrawer(const LeaderboardScreen()),
            ),

            if (!isGuest)
              ListTile(
                leading: const Icon(Icons.smart_toy),
                title: const Text("Database Assistant"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/chatbot');
                },
              ),

            if (!isGuest)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Profile"),
                onTap: () => _navigateAndCloseDrawer(const ProfileScreen()),
              ),
            if (!isGuest)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () => _navigateAndCloseDrawer(const SettingsScreen()),
              ),

            if (isGuest)
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text("Sign Up"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/signup');
                },
              ),

            SwitchListTile(
              secondary: const Icon(Icons.dark_mode),
              title: const Text("Dark Mode"),
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (val) => themeProvider.toggleTheme(val),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await AuthService().logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
