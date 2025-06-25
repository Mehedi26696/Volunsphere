import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';  
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/certificate_service.dart';
import '../utils/api.dart';
import 'edit_profile_screen.dart';
import '../utils/certificate_generator.dart';
import 'package:pdf/pdf.dart';  

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isUploading = false;
  bool isGeneratingCertificate = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      error = null;
    });
    try {
      final profile = await ProfileService().getUserProfile();
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load profile. Pull down to retry.";
      });
    }
  }

  String cacheBustedUrl(String url) {
    return '$url?ts=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose image source",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.teal,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() => isUploading = true);

    final token = await AuthService().getAccessToken();
    if (token == null) {
      if (mounted) {
        await _showErrorDialog("Unauthorized. Please log in again.");
        setState(() => isUploading = false);
      }
      return;
    }

    final uri = Uri.parse('$baseUrl/upload-profile-image');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('file', croppedFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (mounted) {
      if (response.statusCode == 200) {
        await _loadProfile();
        await _showInfoDialog("Profile image updated!");
      } else {
        await _showErrorDialog("Upload failed: ${response.statusCode}");
      }
      setState(() => isUploading = false);
    }
  }

  Future<void> _generateCertificate() async {
    setState(() => isGeneratingCertificate = true);
    try {
      final data = await CertificateService.getCertificateData();
      if (data == null) throw Exception("Certificate data fetch failed");

      final pdfBytes = await generateCertificatePdf(
        name: "${userProfile?['first_name'] ?? ''} ${userProfile?['last_name'] ?? ''}",
        eventsJoined: data['events_joined'] ?? 0,
        hoursVolunteered: (data['hours_volunteered'] ?? 0.0).toDouble(),
        averageRating: (data['average_rating'] ?? 0.0).toDouble(),
        joinedEvents: List<String>.from(data['joined_event_titles'] ?? []),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Volunteer_Certificate.pdf',
      );
    } catch (e) {
      if (mounted) {
        await _showErrorDialog("Failed to generate certificate: $e");
      }
    }
    if (mounted) setState(() => isGeneratingCertificate = false);
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))
        ],
      ),
    );
  }

  Future<void> _showInfoDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return Scaffold(
        body: error != null
            ? RefreshIndicator(
                onRefresh: _loadProfile,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Center(
                      heightFactor: 15,
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final profileImageUrl = userProfile!['profile_image_url'];
    final hasImage = profileImageUrl != null && profileImageUrl.toString().trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(userProfile: userProfile!),
                ),
              );
              if (updated == true) {
                _loadProfile();
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        child: ClipOval(
                          child: hasImage
                              ? FadeInImage.assetNetwork(
                                  placeholder: 'assets/images/default_profile.jpg',
                                  image: cacheBustedUrl(profileImageUrl),
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  imageErrorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/default_profile.jpg',
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/default_profile.jpg',
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      isUploading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              onPressed: isUploading ? null : _uploadImage,
                              icon: const Icon(Icons.upload_file),
                              label: const Text("Update Profile Picture"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _profileRow(Icons.person, "Name",
                          "${userProfile!['first_name'] ?? ''} ${userProfile!['last_name'] ?? ''}"),
                      _profileRow(Icons.account_circle, "Username", userProfile!['username'] ?? ''),
                      _profileRow(Icons.email, "Email", userProfile!['email'] ?? ''),
                      _profileRow(Icons.phone, "Phone", userProfile!['phone'] ?? ''),
                      _profileRow(Icons.location_city, "City", userProfile!['city'] ?? ''),
                      _profileRow(Icons.flag, "Country", userProfile!['country'] ?? ''),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isGeneratingCertificate
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton.extended(
              onPressed: _generateCertificate,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Generate Certificate"),
              backgroundColor: Colors.teal.shade700,
            ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    )),
                Text(value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
