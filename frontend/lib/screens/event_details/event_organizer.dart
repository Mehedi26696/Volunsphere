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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0, top: 16.0),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: Colors.teal, size: 22),
          if (icon != null) const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGuest) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, "Organizer", icon: Icons.person),
        if (isLoadingCreator)
          const Center(child: CircularProgressIndicator())
        else if (creatorInfo != null)
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.teal.shade100,
                backgroundImage:
                    creatorInfo!['profile_image_url'] != null
                        ? NetworkImage(creatorInfo!['profile_image_url'])
                        : null,
                child:
                    creatorInfo!['profile_image_url'] == null
                        ? const Icon(Icons.person, color: Colors.teal, size: 28)
                        : null,
              ),
              title: Text(
                creatorInfo!['username'] ?? 'Creator',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              subtitle: Text(
                creatorInfo!['email'] ?? '',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.teal.shade700,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.teal),
                onPressed: () => onNavigateToProfile(creatorInfo!),
                tooltip: "View Profile",
              ),
            ),
          ),
      ],
    );
  }
}
