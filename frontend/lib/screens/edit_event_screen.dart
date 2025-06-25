import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/event_model.dart';
import '../services/events_service.dart';
import 'map_picker_screen.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;

  const EditEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _dateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  double? _latitude;
  double? _longitude;

  final ImagePicker _picker = ImagePicker();
  List<File> _pickedImages = [];
  late List<String> _existingImageUrls;

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description ?? '');
    _locationController = TextEditingController(text: widget.event.location ?? '');

    _selectedDate = DateTime(
      widget.event.startDatetime.year,
      widget.event.startDatetime.month,
      widget.event.startDatetime.day,
    );
    _dateController = TextEditingController(text: _formatDate(_selectedDate!));

    _startTime = TimeOfDay.fromDateTime(widget.event.startDatetime);
    _endTime = TimeOfDay.fromDateTime(widget.event.endDatetime);

    _latitude = widget.event.latitude;
    _longitude = widget.event.longitude;
    _existingImageUrls = List<String>.from(widget.event.imageUrls ?? []);

    if (_latitude != null && _longitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('event_location'),
          position: LatLng(_latitude!, _longitude!),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _startTimeController = TextEditingController(text: _startTime!.format(context));
        _endTimeController = TextEditingController(text: _endTime!.format(context));
      });
    });
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.teal,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialTime = isStart ? _startTime ?? TimeOfDay.now() : _endTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.teal,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          _startTimeController.text = picked.format(context);
        } else {
          _endTime = picked;
          _endTimeController.text = picked.format(context);
        }
      });
    }
  }

  bool _validateDateTimes() {
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select date, start time and end time.")),
      );
      return false;
    }

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (!endDateTime.isAfter(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time.")),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickMapLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _latitude ?? 23.8103,
          initialLng: _longitude ?? 90.4125,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        _locationController.text = result['address'] ?? '';
        _markers = {
          Marker(
            markerId: const MarkerId('event_location'),
            position: LatLng(_latitude!, _longitude!),
          ),
        };
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(_latitude!, _longitude!)),
      );
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      if (pickedFiles.length + _pickedImages.length + _existingImageUrls.length > 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can only select up to 3 images total.")),
        );
        return;
      }
      setState(() {
        _pickedImages.addAll(pickedFiles.map((e) => File(e.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields and select a map location.")),
      );
      return;
    }

    if (!_validateDateTimes()) return;

    setState(() => _isLoading = true);

    List<String> uploadedUrls = [];
    try {
      if (_pickedImages.isNotEmpty) {
        uploadedUrls = await EventsService.uploadEventImages(widget.event.id.toString(), _pickedImages);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload failed: $e")),
      );
      return;
    }

    final allImageUrls = [..._existingImageUrls, ...uploadedUrls];

    try {
      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );

      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      final duration = endDateTime.difference(startDateTime).inMinutes;

      final updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startDatetime: startDateTime,
        endDatetime: endDateTime,
        durationMinutes: duration,
        latitude: _latitude,
        longitude: _longitude,
        imageUrls: allImageUrls,
      );

      final success = await EventsService.updateEvent(
        widget.event.id.toString(),
        updatedEvent,
        imageUrls: allImageUrls,
      );

      if (!success) throw Exception("Failed to update event");
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update event: $e")),
      );
      return;
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event updated successfully!")),
      );
    }
  }

  InputDecoration _modernInputDecoration({
    required String label,
    IconData? icon,
    bool filled = true,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.teal) : null,
      filled: filled,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.teal.shade100),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.teal.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.teal, width: 2),
      ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: Colors.teal.shade700,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Edit Event'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.teal),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.teal.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: _startTimeController == null || _endTimeController == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _sectionTitle("Event Details"),
                    TextFormField(
                      controller: _titleController,
                      decoration: _modernInputDecoration(label: 'Title *', icon: Icons.title),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _modernInputDecoration(label: 'Description', icon: Icons.description),
                      maxLines: 3,
                    ),
                    _sectionTitle("Date & Time"),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: _modernInputDecoration(
                              label: 'Date *',
                              icon: Icons.calendar_today,
                            ),
                            readOnly: true,
                            onTap: _pickDate,
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Date is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            decoration: _modernInputDecoration(
                              label: 'Start Time *',
                              icon: Icons.access_time,
                            ),
                            readOnly: true,
                            onTap: () => _pickTime(isStart: true),
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'Start time is required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: _modernInputDecoration(
                              label: 'End Time *',
                              icon: Icons.access_time,
                            ),
                            readOnly: true,
                            onTap: () => _pickTime(isStart: false),
                            validator: (value) =>
                                (value == null || value.isEmpty) ? 'End time is required' : null,
                          ),
                        ),
                      ],
                    ),
                    _sectionTitle("Location"),
                    TextFormField(
                      controller: _locationController,
                      decoration: _modernInputDecoration(
                        label: 'Location',
                        icon: Icons.location_on,
                        suffix: IconButton(
                          icon: const Icon(Icons.map, color: Colors.teal),
                          onPressed: _pickMapLocation,
                          tooltip: "Pick on Map",
                        ),
                      ),
                      readOnly: true,
                      onTap: _pickMapLocation,
                    ),
                    if (_locationController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Card(
                          color: Colors.teal.shade50,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.place, color: Colors.teal.shade400),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationController.text,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 180,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_latitude!, _longitude!),
                                zoom: 15,
                              ),
                              markers: _markers,
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                              myLocationEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                            ),
                          ),
                        ),
                      ),
                    _sectionTitle("Images"),
                    if (_existingImageUrls.isNotEmpty)
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _existingImageUrls.length,
                          itemBuilder: (context, index) {
                            final url = _existingImageUrls[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _existingImageUrls.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    if (_pickedImages.isNotEmpty)
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _pickedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _pickedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate, color: Colors.teal),
                        label: const Text("Pick Images (max 3)", style: TextStyle(color: Colors.teal)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.teal.shade200),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _pickImages,
                      ),
                    ),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              child: const Text("Update Event"),
                            ),
                          ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
      ),
    );
  }
}
