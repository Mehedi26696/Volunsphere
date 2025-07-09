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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          content: Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: Text(
                        "Sign Up Required",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 24 : 20,
                          color: const Color(0xFF27264A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 24 : 20),
                Text(
                  "You need to sign up to view user profiles and join our community!",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isTablet ? 16 : 14,
                    color: const Color(0xFF626C7A),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: isTablet ? 32 : 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF626C7A).withValues(alpha: 0.1),
                              const Color(0xFF626C7A).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 20 : 16,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF626C7A,
                            ).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isTablet ? 20 : 16,
                              ),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: const Color(0xFF626C7A),
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 18 : 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                          ),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 20 : 16,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/signup');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isTablet ? 20 : 16,
                              ),
                            ),
                          ),
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: isTablet ? 18 : 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    if (_loading) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(isTablet ? 50 : 40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading leaderboard...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF27264A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(isTablet ? 30 : 20),
          padding: EdgeInsets.all(isTablet ? 40 : 30),
          decoration: BoxDecoration(
            color: Colors.red.shade50.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.red.shade200.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade500],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: isTablet ? 40 : 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading data',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $_error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_leaderboard.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(isTablet ? 30 : 20),
          padding: EdgeInsets.all(isTablet ? 50 : 40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF626C7A).withValues(alpha: 0.2),
                      const Color(0xFF626C7A).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.leaderboard_rounded,
                  size: isTablet ? 56 : 48,
                  color: const Color(0xFF626C7A).withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No leaderboard data',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF626C7A).withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child:
          isDesktop
              ? GridView.builder(
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? 12 : 8,
                  horizontal: isTablet ? 24 : 0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3.5,
                ),
                itemCount: _leaderboard.length,
                physics: const ClampingScrollPhysics(),
                itemBuilder:
                    (context, index) => _buildLeaderboardCard(
                      context,
                      index,
                      isTablet,
                      isDesktop,
                    ),
              )
              : ListView.separated(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 12 : 8),
                itemCount: _leaderboard.length,
                separatorBuilder:
                    (_, __) => SizedBox(height: isTablet ? 16 : 12),
                physics: const ClampingScrollPhysics(),
                itemBuilder:
                    (context, index) => _buildLeaderboardCard(
                      context,
                      index,
                      isTablet,
                      isDesktop,
                    ),
              ),
    );
  }

  Widget _buildLeaderboardCard(
    BuildContext context,
    int index,
    bool isTablet,
    bool isDesktop,
  ) {
    final user = _leaderboard[index];
    final username = user['username'] ?? 'Unknown';
    final profileUrl = user['profile_image_url'] as String?;
    final eventsJoined = user['events_joined'] ?? 0;
    final avgRating = _formatNumber(user['avg_rating'], decimals: 2);
    final totalHours = _formatNumber(user['total_hours'], decimals: 1);
    final overallScore = _formatNumber(user['overall_score'], decimals: 2);

    // Better color palette for white background
    final rankColors = [
      [const Color(0xFFE91E63), const Color(0xFFF06292)], // Pink
      [const Color(0xFF9C27B0), const Color(0xFFBA68C8)], // Purple
      [const Color(0xFF3F51B5), const Color(0xFF7986CB)], // Indigo
      [const Color(0xFF2196F3), const Color(0xFF64B5F6)], // Blue
      [const Color(0xFF00BCD4), const Color(0xFF4DD0E1)], // Cyan
      [const Color(0xFF4CAF50), const Color(0xFF81C784)], // Green
      [const Color(0xFFFF9800), const Color(0xFFFFB74D)], // Orange
      [const Color(0xFF795548), const Color(0xFFA1887F)], // Brown
    ];

    final colorIndex =
        index < rankColors.length ? index : (index % rankColors.length);
    final rankGradient = rankColors[colorIndex];

    return InkWell(
      onTap: () {
        if (_isGuest) {
          _showSignupDialog();
        } else {
          final userMap = Map<String, dynamic>.from(user);
          userMap['id'] = userMap['uid'];
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileScreen(user: userMap)),
          );
        }
      },
      borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          border: Border.all(
            color: rankGradient[0].withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: rankGradient[0].withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  child:
                      isDesktop
                          ? _buildDesktopLayout(
                            index,
                            rankGradient,
                            username,
                            profileUrl,
                            eventsJoined,
                            avgRating,
                            totalHours,
                            overallScore,
                            isTablet,
                          )
                          : _buildMobileLayout(
                            index,
                            rankGradient,
                            username,
                            profileUrl,
                            eventsJoined,
                            avgRating,
                            totalHours,
                            overallScore,
                            isTablet,
                          ),
                ),

                // Bottom Accent
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: rankGradient),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(isTablet ? 24 : 20),
                      bottomRight: Radius.circular(isTablet ? 24 : 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    int index,
    List<Color> rankGradient,
    String username,
    String? profileUrl,
    int eventsJoined,
    String avgRating,
    String totalHours,
    String overallScore,
    bool isTablet,
  ) {
    return Row(
      children: [
        // Rank Badge
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 16 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: rankGradient),
            borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
            boxShadow: [
              BoxShadow(
                color: rankGradient[0].withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 20 : 16,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(width: isTablet ? 20 : 16),

        // Profile Picture
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 18 : 15),
            border: Border.all(
              color: rankGradient[0].withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: rankGradient[0].withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isTablet ? 16 : 13),
            child: Container(
              width: isTablet ? 60 : 50,
              height: isTablet ? 60 : 50,
              color: Colors.white,
              child:
                  profileUrl != null
                      ? Image.network(
                        profileUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person_rounded,
                            size: isTablet ? 30 : 25,
                            color: rankGradient[0],
                          );
                        },
                      )
                      : Icon(
                        Icons.person_rounded,
                        size: isTablet ? 30 : 25,
                        color: rankGradient[0],
                      ),
            ),
          ),
        ),
        SizedBox(width: isTablet ? 20 : 16),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isTablet ? 20 : 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF27264A),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              Wrap(
                spacing: isTablet ? 8 : 6,
                runSpacing: 4,
                children: [
                  _buildStatChip(
                    'Events',
                    eventsJoined.toString(),
                    const Color(0xFF4CAF50),
                    isTablet,
                  ),
                  _buildStatChip(
                    'Rating',
                    avgRating,
                    const Color(0xFFFF9800),
                    isTablet,
                  ),
                  _buildStatChip(
                    'Hours',
                    totalHours,
                    const Color(0xFF2196F3),
                    isTablet,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Score Display
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 18 : 14,
            vertical: isTablet ? 14 : 10,
          ),
          decoration: BoxDecoration(
            color: rankGradient[0].withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: Border.all(
              color: rankGradient[0].withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Text(
                _sortBy == 'rating'
                    ? avgRating
                    : _sortBy == 'hours'
                    ? totalHours
                    : _sortBy == 'events'
                    ? eventsJoined.toString()
                    : overallScore,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 20 : 16,
                  color: rankGradient[0],
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                _sortBy == 'rating'
                    ? 'Rating'
                    : _sortBy == 'hours'
                    ? 'Hours'
                    : _sortBy == 'events'
                    ? 'Events'
                    : 'Score',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isTablet ? 11 : 9,
                  color: rankGradient[0].withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    int index,
    List<Color> rankGradient,
    String username,
    String? profileUrl,
    int eventsJoined,
    String avgRating,
    String totalHours,
    String overallScore,
    bool isTablet,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // Rank Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: rankGradient),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: rankGradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Profile Picture
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: rankGradient[0].withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 56,
                  height: 56,
                  color: Colors.white,
                  child:
                      profileUrl != null
                          ? Image.network(
                            profileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person_rounded,
                                size: 28,
                                color: rankGradient[0],
                              );
                            },
                          )
                          : Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: rankGradient[0],
                          ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Username
            Expanded(
              child: Text(
                username,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27264A),
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Score Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: rankGradient[0].withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: rankGradient[0].withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _sortBy == 'rating'
                        ? avgRating
                        : _sortBy == 'hours'
                        ? totalHours
                        : _sortBy == 'events'
                        ? eventsJoined.toString()
                        : overallScore,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: rankGradient[0],
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sortBy == 'rating'
                        ? 'Rating'
                        : _sortBy == 'hours'
                        ? 'Hours'
                        : _sortBy == 'events'
                        ? 'Events'
                        : 'Score',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: rankGradient[0].withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Stats row for desktop
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatChip(
              'Events',
              eventsJoined.toString(),
              const Color(0xFF4CAF50),
              true,
            ),
            _buildStatChip('Rating', avgRating, const Color(0xFFFF9800), true),
            _buildStatChip('Hours', totalHours, const Color(0xFF2196F3), true),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Purple App Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 30 : 20,
                vertical: isTablet ? 20 : 16,
              ),
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
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: isTablet ? 24 : 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.all(isTablet ? 12 : 10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Leaderboard",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: isTablet ? 26 : 22,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: Icon(
                        Icons.sort_rounded,
                        color: Colors.white,
                        size: isTablet ? 24 : 20,
                      ),
                      onSelected: (value) {
                        setState(() {
                          _sortBy = value;
                        });
                        _fetchLeaderboard();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (context) {
                        return sortOptions.entries
                            .map(
                              (e) => PopupMenuItem<String>(
                                value: e.key,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: isTablet ? 16 : 14,
                                      color: const Color(0xFF27264A),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList();
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.all(isTablet ? 12 : 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 30 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16,
                        vertical: isTablet ? 14 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2CBF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                        border: Border.all(
                          color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Sorted: ${sortOptions[_sortBy]}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B2CBF),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 20 : 16),
                    Expanded(child: _buildList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    Color color, [
    bool isTablet = false,
  ]) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 8 : 6,
        vertical: isTablet ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: isTablet ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
