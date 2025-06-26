import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<String> images = [
    'assets/images/Onboarding0.png',
    'assets/images/Onboarding1.png',
    'assets/images/Onboarding2.png',
  ];

  final List<String> titles = [
    'Welcome to Volunsphere',
    'How It Works',
    'Create Impact Together',
  ];

  final List<String> subtitles = [
    'Connecting volunteers with meaningful opportunities',
    'Discover opportunities & log your hours.',
    'Track your impact and grow as a team.',
  ];

  void _nextPage() async {
    if (_currentPage < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
       
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  Widget _buildArrowControls() {
    if (_currentPage == 0) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF9929ea).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Color(0xFF9929ea)),
            onPressed: _nextPage,
            iconSize: 28,
            padding: const EdgeInsets.all(12),
          ),
        ),
      );
    } else if (_currentPage == 1) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9929ea).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9929ea)),
              onPressed: _prevPage,
              iconSize: 28,
              padding: const EdgeInsets.all(12),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9929ea).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF9929ea),
              ),
              onPressed: _nextPage,
              iconSize: 28,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9929ea),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            elevation: 8,
            shadowColor: const Color(0xFF9929ea).withValues(alpha: 0.4),
          ),
          child: const Text(
            'Get Started',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: _currentPage == index ? 24 : 12,
          height: 12,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? const Color(0xFF9929ea)
                    : const Color(0xFF9929ea).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: 3,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 225, 192, 255),
                      Color.fromARGB(255, 255, 255, 255),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF9929ea).withValues(alpha: 0.8),
                              const Color(0xFF9929ea),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF9929ea,
                              ).withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          index == 0
                              ? Icons.volunteer_activism
                              : index == 1
                              ? Icons.search
                              : Icons.group,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 60),
                      Text(
                        titles[index],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF27264A),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        subtitles[index],
                        style: const TextStyle(
                          color: Color(0xFF6E6E86),
                          fontSize: 18,
                          fontFamily: 'Poppins',
                          letterSpacing: -0.5,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 80),
                      _buildDots(),
                      const SizedBox(height: 40),
                      _buildArrowControls(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
