import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/event_model.dart';
import '../services/events_service.dart';
import '../services/certificate_service.dart';
import 'event_details_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserProfileScreen({super.key, required this.user});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<String> joinedEvents = [];
  double totalHours = 0.0;
  double averageRating = 0.0;
  int eventsJoined = 0;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final userId = widget.user['id'] ?? widget.user['uid'];
    final data = await CertificateService.getCertificateDataForUser(userId);

    if (data != null) {
      setState(() {
        eventsJoined = data['events_joined'];
        totalHours = (data['hours_volunteered'] as num?)?.toDouble() ?? 0.0;
        averageRating = (data['average_rating'] as num?)?.toDouble() ?? 0.0;
        joinedEvents = List<String>.from(data['joined_event_titles'] ?? []);
      });
    }
  }

  Future<void> _makeDirectCall(String phoneNumber) async {
    final permissionStatus = await Permission.phone.status;
    if (permissionStatus.isGranted) {
      await FlutterPhoneDirectCaller.callNumber(phoneNumber);
    } else {
      final result = await Permission.phone.request();
      if (result.isGranted) {
        await FlutterPhoneDirectCaller.callNumber(phoneNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final String? phoneNumber = user['phone'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(user['username'] ?? 'User Profile'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    user['profile_image_url'] != null
                        ? NetworkImage(user['profile_image_url'])
                        : null,
                child:
                    user['profile_image_url'] == null
                        ? const Icon(Icons.person, size: 64, color: Colors.grey)
                        : null,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "@${user['username'] ?? ''}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 24),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.teal.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    _contactRow(
                      icon: Icons.email,
                      label: user['email'] ?? 'N/A',
                      iconColor: Colors.teal,
                    ),
                    const Divider(height: 32),
                    InkWell(
                      onTap: () async {
                        if (phoneNumber != null && phoneNumber.isNotEmpty) {
                          await _makeDirectCall(phoneNumber);
                        }
                      },
                      child: _contactRow(
                        icon: Icons.phone,
                        label: phoneNumber ?? 'N/A',
                        iconColor: Colors.teal,
                        isLink: phoneNumber != null && phoneNumber.isNotEmpty,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: Colors.teal.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Profile Stats",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("Events", eventsJoined.toString()),
                        _buildStat("Hours", totalHours.toStringAsFixed(1)),
                        _buildStat("Rating", averageRating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Joined Events",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (joinedEvents.length > 3)
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                              title: const Text("All Events"),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: joinedEvents.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(joinedEvents[index]),
                                    );
                                  },
                                ),
                              ),
                            ),
                      );
                    },
                    child: const Text(
                      "See All",
                      style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Column(
              children:
                  joinedEvents.take(3).map((title) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      child: ListTile(
                        title: Text(title),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.teal,
                        ),
                        onTap: () async {
                          final allEvents = await EventsService.getAllEvents();
                          final event = allEvents.firstWhere(
                            (e) => e.title == title,
                            orElse: () => null as Event,
                          );
                          if (event != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        EventDetailsScreen(eventId: event.id),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Event not found")),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required Color iconColor,
    bool isLink = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isLink ? Colors.blue.shade700 : Colors.grey.shade800,
              decoration: isLink ? TextDecoration.underline : null,
              fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
