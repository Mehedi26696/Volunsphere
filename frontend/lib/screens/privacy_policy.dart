import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 70),
                  const SizedBox(height: 12),
                  const Text(
                    'Volunsphere Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF27264A),
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _PolicySection(
              title: '1. Introduction',
              content:
                  'Volunsphere is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our app. By using Volunsphere, you agree to the collection and use of information in accordance with this policy.',
            ),
            const _PolicySection(
              title: '2. Information We Collect',
              content:
                  'We may collect personal information such as your name, email address, profile photo, and other details you provide when registering or updating your profile. We also collect non-personal information such as device type, usage data, and analytics to improve our services.',
            ),
            const _PolicySection(
              title: '3. How We Use Your Information',
              content:
                  'We use your information to:\n'
                  '- Provide and maintain the app\n'
                  '- Personalize your experience\n'
                  '- Communicate with you about updates, events, and support\n'
                  '- Improve our app and develop new features\n'
                  '- Ensure the security and integrity of our services',
            ),
            const _PolicySection(
              title: '4. Sharing Your Information',
              content:
                  'We do not sell or rent your personal information. We may share your information with trusted third parties only to provide essential services (such as authentication, analytics, or notifications) and only as necessary for app functionality. We may also disclose information if required by law.',
            ),
            const _PolicySection(
              title: '5. Data Security',
              content:
                  'We implement reasonable security measures to protect your data. However, no method of transmission over the internet or electronic storage is 100% secure. We encourage you to use strong passwords and keep your login credentials confidential.',
            ),
            const _PolicySection(
              title: '6. Your Choices',
              content:
                  'You may update or delete your account information at any time from within the app. You may also contact us for assistance. You can opt out of non-essential communications at any time.',
            ),
            const _PolicySection(
              title: '7. Children’s Privacy',
              content:
                  'Volunsphere does not knowingly collect personal information from children under 13. If you believe a child has provided us with personal information, please contact us so we can take appropriate action.',
            ),
            const _PolicySection(
              title: '8. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy in the app. Your continued use of Volunsphere after changes are made constitutes your acceptance of the new policy.',
            ),
            const _PolicySection(
              title: '9. Contact Us',
              content:
                  'If you have any questions or concerns about this Privacy Policy or our practices, please contact us at: hasanmehedi26696@gmail.com',
            ),
            const SizedBox(height: 32),
            const Text(
              'Last updated: July 15, 2025',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF626C7A),
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;

  const _PolicySection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF27264A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: Color(0xFF626C7A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
