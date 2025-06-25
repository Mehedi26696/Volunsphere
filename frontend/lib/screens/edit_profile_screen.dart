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
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Username read-only
                TextFormField(
                  initialValue: username,
                  readOnly: true,
                  decoration: _inputDecoration("Username", Icons.person),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email", Icons.email),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration("First Name", Icons.badge),
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration("Last Name", Icons.badge_outlined),
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration("Phone", Icons.phone),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Phone is required";
                    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(value)) {
                      return "Enter a valid phone number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                
                _loadingCountries
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownSearch<String>(
                        items: _countryList,
                        selectedItem: _selectedCountry,
                        popupProps: const PopupProps.bottomSheet(
                          showSearchBox: true,
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
                const SizedBox(height: 16),
                
                _loadingCities
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownSearch<String>(
                        items: _cityList,
                        selectedItem: _selectedCity,
                        popupProps: const PopupProps.bottomSheet(
                          showSearchBox: true,
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
                      
              

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text("Save Changes"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
