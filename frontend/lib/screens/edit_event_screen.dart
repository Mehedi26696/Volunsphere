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
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFF626C7A),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF7B2CBF)) : null,
      filled: filled,
      fillColor: Colors.white.withValues(alpha: 0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF7B2CBF),
          width: 2,
        ),
      ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF27264A),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Purple App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Edit Event",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _startTimeController == null || _endTimeController == null
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B2CBF).withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Loading event...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF27264A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFF7B2CBF).withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B2CBF).withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle("Event Details"),
                              TextFormField(
                                controller: _titleController,
                                decoration: _modernInputDecoration(
                                  label: 'Event Title *',
                                  icon: Icons.title_rounded,
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty) ? 'Title is required' : null,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF27264A),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: _modernInputDecoration(
                                  label: 'Event Description',
                                  icon: Icons.description_rounded,
                                ),
                                maxLines: 4,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF27264A),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              _sectionTitle("Date & Time"),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _dateController,
                                      decoration: _modernInputDecoration(
                                        label: 'Date *',
                                        icon: Icons.calendar_today_rounded,
                                      ),
                                      readOnly: true,
                                      onTap: _pickDate,
                                      validator: (value) =>
                                          (value == null || value.isEmpty) ? 'Date is required' : null,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF27264A),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _startTimeController,
                                      decoration: _modernInputDecoration(
                                        label: 'Start Time *',
                                        icon: Icons.access_time_rounded,
                                      ),
                                      readOnly: true,
                                      onTap: () => _pickTime(isStart: true),
                                      validator: (value) =>
                                          (value == null || value.isEmpty) ? 'Start time is required' : null,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF27264A),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _endTimeController,
                                      decoration: _modernInputDecoration(
                                        label: 'End Time *',
                                        icon: Icons.event_rounded,
                                      ),
                                      readOnly: true,
                                      onTap: () => _pickTime(isStart: false),
                                      validator: (value) =>
                                          (value == null || value.isEmpty) ? 'End time is required' : null,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF27264A),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              _sectionTitle("Location"),
                              TextFormField(
                                controller: _locationController,
                                decoration: _modernInputDecoration(
                                  label: 'Location',
                                  icon: Icons.location_on_rounded,
                                  suffix: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                                      onPressed: _pickMapLocation,
                                      tooltip: "Pick on Map",
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        padding: const EdgeInsets.all(6),
                                      ),
                                    ),
                                  ),
                                ),
                                readOnly: true,
                                onTap: _pickMapLocation,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Color(0xFF27264A),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),

                              if (_locationController.text.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF4CAF50).withValues(alpha: 0.1),
                                        const Color(0xFF4CAF50).withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.place_rounded, color: const Color(0xFF4CAF50)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _locationController.text,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF4CAF50),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_latitude != null && _longitude != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7B2CBF).withValues(alpha: 0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: SizedBox(
                                      height: 200,
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
                              ],

                              _sectionTitle("Event Images"),
                              if (_existingImageUrls.isNotEmpty) ...[
                                Container(
                                  height: 120,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _existingImageUrls.length,
                                    itemBuilder: (context, index) {
                                      final url = _existingImageUrls[index];
                                      return Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: Image.network(
                                                  url,
                                                  width: 120,
                                                  height: 120,
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
                                                    _existingImageUrls.removeAt(index);
                                                  });
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [Colors.red.shade400, Colors.red.shade500],
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.red.withValues(alpha: 0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  padding: const EdgeInsets.all(6),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              if (_pickedImages.isNotEmpty) ...[
                                Container(
                                  height: 120,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _pickedImages.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(0xFF7B2CBF).withValues(alpha: 0.2),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF7B2CBF).withValues(alpha: 0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(14),
                                                child: Image.file(
                                                  _pickedImages[index],
                                                  width: 120,
                                                  height: 120,
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
                                                    gradient: LinearGradient(
                                                      colors: [Colors.red.shade400, Colors.red.shade500],
                                                    ),
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.red.withValues(alpha: 0.3),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  padding: const EdgeInsets.all(6),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFF9800).withValues(alpha: 0.1),
                                      const Color(0xFFFFB74D).withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _pickImages,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            color: const Color(0xFFFF9800),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            "Pick Images (max 3)",
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              color: Color(0xFFFF9800),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Submit Button
                              _isLoading
                                  ? Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7B2CBF).withValues(alpha: 0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 18),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                        ),
                                        child: const Text(
                                          "Update Event",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
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
      ),
    );
  }
}
