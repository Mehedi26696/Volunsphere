import 'package:flutter/material.dart';

class EventOrganizer extends StatelessWidget {
  final Map<String, dynamic>? creatorInfo;
  final bool isLoadingCreator;
  final bool isGuest;
  final Function(Map<String, dynamic>) onNavigateToProfile;

  const EventOrganizer({
    super.key,
    required this.creatorInfo,
    required this.isLoadingCreator,
    required this.isGuest,
    required this.onNavigateToProfile,
  });

  Widget _buildSectionTitle(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon ?? Icons.person_rounded,
                color: const Color(0xFF388E3C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF27264A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, "Organizer", icon: Icons.person_rounded),
          if (isLoadingCreator)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            )
            else if (creatorInfo != null)
            Container(
              decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.15), // Darker green
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.08), // Darker green
                blurRadius: 20,
                offset: const Offset(0, 8),
                ),
              ],
              ),
              child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () => onNavigateToProfile(creatorInfo!),
                hoverColor: const Color(0xFF2E7D32).withOpacity(0.05), // Darker green
                child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                  Container(
                    decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.3), // Darker green
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.2), // Darker green
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      ),
                    ],
                    ),
                    child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage: creatorInfo!['profile_image_url'] != null
                      ? NetworkImage(creatorInfo!['profile_image_url'])
                      : null,
                    child: creatorInfo!['profile_image_url'] == null
                      ? const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF2E7D32), // Darker green
                        size: 28,
                        )
                      : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                      creatorInfo!['username'] ?? 'Creator',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF27264A),
                        letterSpacing: -0.5,
                      ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                      creatorInfo!['email'] ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: const Color(0xFF626C7A).withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                      ),
                    ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1), // Darker green
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.2), // Darker green
                      width: 1,
                    ),
                    ),
                    child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: const Color(0xFF2E7D32), // Darker green
                    size: 16,
                    ),
                  ),
                  ],
                ),
                ),
              ),
              ),
            ),
        ],
      ),
    );
  }
}
