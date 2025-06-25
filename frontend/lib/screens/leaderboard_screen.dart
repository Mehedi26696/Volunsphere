import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/leaderboard_service.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _sortBy = 'overall';
  bool _loading = false;
  List<dynamic> _leaderboard = [];
  String? _error;
  bool _isGuest = false;

  final Map<String, String> sortOptions = {
    'rating': 'By Rating',
    'hours': 'By Hours',
    'events': 'By Events',
    'overall': 'Overall',
  };

  @override
  void initState() {
    super.initState();
    _checkIfGuest();
    _fetchLeaderboard();
  }

  Future<void> _checkIfGuest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  void _showSignupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sign Up Required"),
          content: const Text("You need to sign up to view user profiles."),
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

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await LeaderboardService.fetchLeaderboard(_sortBy);
      setState(() {
        _leaderboard = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatNumber(dynamic value, {int decimals = 2}) {
    if (value == null) return '0';
    double? numValue;

    if (value is num) {
      numValue = value.toDouble();
    } else if (value is String) {
      numValue = double.tryParse(value);
    }

    if (numValue == null) return '0';
    return numValue.toStringAsFixed(decimals);
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_leaderboard.isEmpty) {
      return const Center(child: Text('No leaderboard data'));
    }

    return ListView.separated(
      itemCount: _leaderboard.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final user = _leaderboard[index];

        final username = user['username'] ?? 'Unknown';
        final profileUrl = user['profile_image_url'] as String?;
        final eventsJoined = user['events_joined'] ?? 0;
        final email = user['email'] ?? 'No email';
        final phone = user['phone'] ?? 'No phone';
        final avgRating = _formatNumber(user['avg_rating'], decimals: 2);
        final totalHours = _formatNumber(user['total_hours'], decimals: 1);
        final overallScore = _formatNumber(user['overall_score'], decimals: 2);

        return InkWell(
          onTap: () {
            if (_isGuest) {
              _showSignupDialog();
            } else {
              
              final userMap = Map<String, dynamic>.from(user);
              userMap['id'] = userMap['uid'];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileScreen(user: userMap),
                ),
              );
            }
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        profileUrl != null ? NetworkImage(profileUrl) : null,
                    child:
                        profileUrl == null
                            ? const Icon(
                              Icons.person,
                              size: 26,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Events: $eventsJoined   •   Rating: $avgRating   •   Hours: $totalHours',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _sortBy == 'rating'
                        ? avgRating
                        : _sortBy == 'hours'
                        ? totalHours
                        : _sortBy == 'events'
                        ? eventsJoined.toString()
                        : overallScore,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _fetchLeaderboard();
            },
            itemBuilder: (context) {
              return sortOptions.entries
                  .map(
                    (e) => PopupMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sorted: ${sortOptions[_sortBy]}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }
}
