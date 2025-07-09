import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  String? _selectedCountry;
  String? _selectedCity;
  List<String> _countryList = [];
  List<String> _cityList = [];

  bool _loadingCountries = true;
  bool _loadingCities = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.userProfile['email']);
    _firstNameController = TextEditingController(text: widget.userProfile['first_name']);
    _lastNameController = TextEditingController(text: widget.userProfile['last_name']);
    _phoneController = TextEditingController(text: widget.userProfile['phone']);
    _selectedCountry = widget.userProfile['country'];
    _selectedCity = widget.userProfile['city'];
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _loadingCountries = true);
    final countries = await LocationService.getCountries();
    setState(() {
      _countryList = countries;
      _loadingCountries = false;
    });
    if (_selectedCountry != null) {
      _loadCities(_selectedCountry!);
    }
  }

  Future<void> _loadCities(String country) async {
    setState(() => _loadingCities = true);
    final cities = await LocationService.getCitiesByCountry(country);
    setState(() {
      _cityList = cities;
      _loadingCities = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedData = {
        "username": widget.userProfile['username'],
        "email": _emailController.text.trim(),
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "city": _selectedCity ?? '',
        "country": _selectedCountry ?? '',
      };

      final success = await ProfileService().updateUserProfile(updatedData);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to update profile',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF626C7A),
        letterSpacing: -0.5,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF9929ea),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF626C7A), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: const Color(0xFF626C7A).withValues(alpha: 0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF9929ea), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.userProfile['username'] ?? 'unknown';

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
                        "Edit Profile",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF27264A),
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9929ea).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 48,
                              color: Color(0xFF9929ea),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          
                          // Username read-only
                          TextFormField(
                            initialValue: username,
                            readOnly: true,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Color(0xFF626C7A),
                            ),
                            decoration: _inputDecoration("Username", Icons.person).copyWith(
                              fillColor: Colors.grey.shade100,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration("Email", Icons.email),
                            validator: (value) =>
                                value == null || value.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 20),

                          // First Name
                          TextFormField(
                            controller: _firstNameController,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration("First Name", Icons.badge),
                          ),
                          const SizedBox(height: 20),

                          // Last Name
                          TextFormField(
                            controller: _lastNameController,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration("Last Name", Icons.badge_outlined),
                          ),
                          const SizedBox(height: 20),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                            ),
                            decoration: _inputDecoration("Phone", Icons.phone),
                            validator: (value) {
                              if (value == null || value.isEmpty) return "Phone is required";
                              if (!RegExp(r'^\+?\d{7,15}$').hasMatch(value)) {
                                return "Enter a valid phone number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Country Dropdown
                          _loadingCountries
                              ? Container(
                                  padding: const EdgeInsets.all(20),
                                  child: const CircularProgressIndicator(
                                    color: Color(0xFF9929ea),
                                  ),
                                )
                              : DropdownSearch<String>(
                                  items: _countryList,
                                  selectedItem: _selectedCountry,
                                  popupProps: const PopupProps.bottomSheet(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Search country...",
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                  ),
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: _inputDecoration("Country", Icons.flag),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCountry = value;
                                      _selectedCity = null;
                                      _cityList = [];
                                    });
                                    if (value != null) {
                                      _loadCities(value);
                                    }
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty ? "Please select a country" : null,
                                ),
                          const SizedBox(height: 20),
                          
                          // City Dropdown
                          _loadingCities
                              ? Container(
                                  padding: const EdgeInsets.all(20),
                                  child: const CircularProgressIndicator(
                                    color: Color(0xFF9929ea),
                                  ),
                                )
                              : DropdownSearch<String>(
                                  items: _cityList,
                                  selectedItem: _selectedCity,
                                  popupProps: const PopupProps.bottomSheet(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        hintText: "Search city...",
                                        prefixIcon: Icon(Icons.search),
                                      ),
                                    ),
                                  ),
                                  dropdownDecoratorProps: DropDownDecoratorProps(
                                    dropdownSearchDecoration: _inputDecoration("City", Icons.location_city),
                                  ),
                                  onChanged: (value) {
                                    setState(() => _selectedCity = value);
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty ? "Please select a city" : null,
                                ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
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
                                    Icons.save,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
