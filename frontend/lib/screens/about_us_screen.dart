import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('About Us'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF27264A),
      ),
      body: Container(
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 80),
                  const SizedBox(height: 12),
                  const Text(
                    'Volunsphere',
                    style: TextStyle(
                      color: Color(0xFF27264A),
                      fontFamily: 'Poppins',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Empowering communities through volunteering.\nConnect, contribute, and make a difference!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w200,
                      color: const Color(0xFF6E6E86),
                      fontSize: 14,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _TeamMemberCard(
              name: 'H.M. Mehedi Hasan',
              imagePath: 'assets/images/mehedi.jpg',
              email: 'hasanmehedi26696@gmail.com',
              github: 'https://github.com/Mehedi26696',
            ),
            const SizedBox(height: 20),
            _TeamMemberCard(
              name: 'Abu Bakar Siddique',
              imagePath: 'assets/images/abs.jpg',
              email: 'bojackabs@gmail.com',
              github: 'https://github.com/Abs-Futy7',
            ),
            const SizedBox(height: 20),
            _TeamMemberCard(
              name: 'Ahil Islam Aurnob',
              imagePath: 'assets/images/aurnob.jpg',
              email: 'aheelislam03@gmail.com',
              github: 'https://github.com/aheel03',
            ),
            const SizedBox(height: 20),
            _TeamMemberCard(
              name: 'S M Shamiun Ferdous',
              imagePath: 'assets/images/shamiun.jpg',
              email: 'shamiunferdous1234@gmail.com',
              github: 'https://github.com/ShamiunFerdous',
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final String email;
  final String github;

  const _TeamMemberCard({
    required this.name,
    required this.imagePath,
    required this.email,
    required this.github,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(imagePath), radius: 35),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF27264A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.email, color: Color(0xFF9929ea), size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          email,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF626C7A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.code, color: Color(0xFF9929ea), size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: InkWell(
                          onTap: () async {
                            final url = Uri.parse(github);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: const Text(
                            'GitHub Profile',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Color(0xFF9929ea),
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
