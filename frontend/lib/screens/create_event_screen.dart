import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../services/events_service.dart';
import '../screens/map_picker_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _startDatetime;
  DateTime? _endDatetime;

  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  List<File> _pickedImages = [];

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      if (pickedFiles.length + _pickedImages.length > 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can only select up to 3 images.")),
        );
        return;
      }
      setState(() {
        _pickedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _pickStartDatetime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDatetime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _startDatetime != null
          ? TimeOfDay.fromDateTime(_startDatetime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _startDatetime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (_endDatetime != null && _endDatetime!.isBefore(_startDatetime!)) {
        _endDatetime = null;
      }
    });
  }

  Future<void> _pickEndDatetime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDatetime ?? (_startDatetime ?? DateTime.now()),
      firstDate: _startDatetime ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _endDatetime != null
          ? TimeOfDay.fromDateTime(_endDatetime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    final chosenEnd = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (_startDatetime != null && chosenEnd.isBefore(_startDatetime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End datetime cannot be before start datetime.")),
      );
      return;
    }

    setState(() {
      _endDatetime = chosenEnd;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _latitude == null ||
        _longitude == null ||
        _startDatetime == null ||
        _endDatetime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields and select start/end datetime and map location.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    List<String> uploadedUrls = [];
    try {
      final tempEventId = DateTime.now().millisecondsSinceEpoch.toString();
      if (_pickedImages.isNotEmpty) {
        uploadedUrls = await EventsService.uploadEventImages(tempEventId, _pickedImages);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload failed: $e")),
      );
      return;
    }

    try {
      await EventsService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startDatetime: _startDatetime!,
        endDatetime: _endDatetime!,
        latitude: _latitude!,
        longitude: _longitude!,
        imageUrls: uploadedUrls,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create event: $e")),
      );
      return;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully!")),
      );
    }
  }

  String? _validateNonEmpty(String? val) {
    if (val == null || val.isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  String _formatDatetime(DateTime? dt) {
    if (dt == null) return 'Select datetime';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.teal,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.teal),
        titleTextStyle: const TextStyle(
          color: Colors.teal,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _sectionTitle("Event Details"),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Title', suffixIcon: const Icon(Icons.title_rounded, color: Colors.teal)),
                      validator: _validateNonEmpty,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Description', suffixIcon: const Icon(Icons.description_rounded, color: Colors.teal)),
                      maxLines: 3,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      readOnly: true,
                      decoration: _inputDecoration('Location (auto-filled from map)', suffixIcon: const Icon(Icons.location_on_rounded, color: Colors.teal)),
                      style: theme.textTheme.bodyLarge,
                    ),
                    _sectionTitle("Date & Time"),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickStartDatetime,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: _inputDecoration('Start Date & Time', suffixIcon: const Icon(Icons.calendar_today, color: Colors.teal)),
                                controller: TextEditingController(text: _formatDatetime(_startDatetime)),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickEndDatetime,
                            child: AbsorbPointer(
                              child: TextFormField(
                                decoration: _inputDecoration('End Date & Time', suffixIcon: const Icon(Icons.calendar_today, color: Colors.teal)),
                                controller: TextEditingController(text: _formatDatetime(_endDatetime)),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _sectionTitle("Location"),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _latitude == null || _longitude == null
                                ? const Text('No location selected', style: TextStyle(fontSize: 13, color: Colors.black54))
                                : Text(
                                    'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}',
                                    style: const TextStyle(fontSize: 13, color: Colors.teal, fontWeight: FontWeight.w500),
                                  ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.map, size: 20),
                            label: const Text("Pick on Map"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              textStyle: const TextStyle(fontWeight: FontWeight.w500),
                              elevation: 0,
                            ),
                            onPressed: _pickLocation,
                          ),
                        ],
                      ),
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 180,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_latitude!, _longitude!),
                              zoom: 14,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("selected_location"),
                                position: LatLng(_latitude!, _longitude!),
                                infoWindow: const InfoWindow(title: "Event Location"),
                              ),
                            },
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            liteModeEnabled: true,
                          ),
                        ),
                      ),
                    ],
                    _sectionTitle("Images"),
                    if (_pickedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _pickedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _pickedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add_photo_alternate, color: Colors.teal),
                        label: const Text("Pick Images (max 3)", style: TextStyle(color: Colors.teal)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.teal,
                          textStyle: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onPressed: _pickImages,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                elevation: 2,
                              ),
                              child: const Text("Create Event"),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
