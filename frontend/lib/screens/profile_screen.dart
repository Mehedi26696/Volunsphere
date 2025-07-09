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

    final uri = Uri.parse('$baseUrl/auth/upload-profile-image');
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
        backgroundColor: const Color(0xFFF4F6F9),
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
          child: error != null
              ? RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: const Color(0xFF9929ea),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Center(
                        heightFactor: 15,
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontFamily: 'Poppins',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF9929ea),
                  ),
                ),
        ),
      );
    }

    final profileImageUrl = userProfile!['profile_image_url'];
    final hasImage = profileImageUrl != null && profileImageUrl.toString().trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
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
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF27264A),
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        "Profile",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF27264A),
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    IconButton(
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
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF9929ea),
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: const Color(0xFF9929ea),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Profile Picture Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF9929ea).withValues(alpha: 0.3),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9929ea).withValues(alpha: 0.1),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade200,
                                  child: ClipOval(
                                    child: hasImage
                                        ? FadeInImage.assetNetwork(
                                            placeholder: 'assets/images/default_profile.jpg',
                                            image: cacheBustedUrl(profileImageUrl),
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            imageErrorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/images/default_profile.jpg',
                                                fit: BoxFit.cover,
                                                width: 120,
                                                height: 120,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            'assets/images/default_profile.jpg',
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "${userProfile!['first_name'] ?? ''} ${userProfile!['last_name'] ?? ''}",
                                style: const TextStyle(
                                  color: Color(0xFF27264A),
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "@${userProfile!['username'] ?? ''}",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6E6E86),
                                  fontSize: 16,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              isUploading
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: const CircularProgressIndicator(
                                        color: Color(0xFF9929ea),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isUploading ? null : _uploadImage,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF9929ea),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 24,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.upload_file,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "Update Profile Picture",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        // Profile Details Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 80),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Personal Information",
                                  style: TextStyle(
                                    color: Color(0xFF27264A),
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _profileRow(Icons.email_outlined, "Email", userProfile!['email'] ?? ''),
                                _profileRow(Icons.phone_outlined, "Phone", userProfile!['phone'] ?? ''),
                                _profileRow(Icons.location_city_outlined, "City", userProfile!['city'] ?? ''),
                                _profileRow(Icons.flag_outlined, "Country", userProfile!['country'] ?? '', isLast: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
              backgroundColor: const Color(0xFF9929ea).withValues(alpha: 0.6),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _generateCertificate,
              backgroundColor: const Color(0xFF9929ea),
              elevation: 8,
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
              ),
              label: const Text(
                "Generate Certificate",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9929ea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF9929ea),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF626C7A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.isEmpty ? "Not provided" : value,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: value.isEmpty ? const Color(0xFF626C7A) : const Color(0xFF27264A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: const Color(0xFF626C7A).withValues(alpha: 0.1),
          ),
      ],
    );
  }
}
