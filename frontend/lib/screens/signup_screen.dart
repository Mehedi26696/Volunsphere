 

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedCountry;
  String? selectedCity;

  List<String> countries = [];
  List<String> cities = [];

  bool isLoading = false;
  bool isCountryLoading = false;
  bool isCityLoading = false;

  bool agreedToTerms = false;
  bool obscurePassword = true;

  double passwordStrength = 0;
  String passwordStrengthText = '';
  Color passwordStrengthColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => isCountryLoading = true);
    try {
      final fetchedCountries = await LocationService.getCountries();
      setState(() {
        countries = fetchedCountries;
        isCountryLoading = false;
      });
    } catch (e) {
      setState(() => isCountryLoading = false);
    }
  }

  Future<void> _loadCities(String country) async {
    setState(() {
      isCityLoading = true;
      cities = [];
      selectedCity = null;
    });
    try {
      final fetchedCities = await LocationService.getCitiesByCountry(country);
      setState(() {
        cities = fetchedCities;
        isCityLoading = false;
      });
    } catch (e) {
      setState(() => isCityLoading = false);
    }
  }

  void checkPasswordStrength(String password) {
    setState(() {
      if (password.isEmpty) {
        passwordStrength = 0;
        passwordStrengthText = '';
        passwordStrengthColor = Colors.red;
      } else if (password.length < 6) {
        passwordStrength = 0.2;
        passwordStrengthText = "Too short";
        passwordStrengthColor = Colors.red;
      } else if (password.length < 8) {
        passwordStrength = 0.4;
        passwordStrengthText = "Weak";
        passwordStrengthColor = Colors.orange;
      } else if (!RegExp(r'[A-Z]').hasMatch(password) ||
          !RegExp(r'[0-9]').hasMatch(password)) {
        passwordStrength = 0.6;
        passwordStrengthText = "Medium";
        passwordStrengthColor = Colors.yellow[800]!;
      } else {
        passwordStrength = 1.0;
        passwordStrengthText = "Strong";
        passwordStrengthColor = Colors.green;
      }
    });
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );
  }

  Future<void> handleSignup(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept the Terms & Conditions")),
      );
      return;
    }

    if (selectedCountry == null || selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select country and city")),
      );
      return;
    }

    setState(() => isLoading = true);

    final firstName = fullNameController.text.trim().split(" ").first;
    final lastName = fullNameController.text.trim().split(" ").skip(1).join(" ");

    try {
      final result = await authService.signupWithResponse(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        firstName: firstName,
        lastName: lastName,
        city: selectedCity!,
        country: selectedCountry!,
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() => isLoading = false);

      if (result.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful!"), backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context);
      } else {
        final detail = json.decode(result.body)['detail'];
        String errorMessage = detail.toString().toLowerCase().contains('email')
            ? "Email already exists"
            : detail.toString().toLowerCase().contains('username')
                ? "Username already exists"
                : "Signup failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup failed. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFd0f0c0), Color(0xFFb2dfdb)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 140, child: Lottie.asset('assets/animations/signup.json')),
                  const Text("Create Your Account",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: usernameController,
                              decoration: _inputDecoration("Username", Icons.person),
                              validator: (value) => value!.isEmpty ? "Username required" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: fullNameController,
                              decoration: _inputDecoration("Full Name", Icons.badge),
                              validator: (value) => value!.isEmpty ? "Full name required" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration("Email", Icons.email),
                              validator: (value) {
                                if (value == null || value.isEmpty) return "Email required";
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(value)) return "Enter valid email";
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration("Phone", Icons.phone),
                              validator: (value) => value!.length < 6 ? "Phone number too short" : null,
                            ),
                            const SizedBox(height: 16),
                            // Country Dropdown Search
                            DropdownSearch<String>(
                              asyncItems: (_) async => countries,
                              selectedItem: selectedCountry,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: _inputDecoration("Country", Icons.flag),
                              ),
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              onChanged: (val) {
                                if (val != null && val != selectedCountry) {
                                  setState(() {
                                    selectedCountry = val;
                                    selectedCity = null;
                                    cities = [];
                                  });
                                  _loadCities(val);
                                }
                              },
                              validator: (value) => value == null ? "Please select a country" : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownSearch<String>(
                              asyncItems: (_) async => cities,
                              selectedItem: selectedCity,
                              enabled: selectedCountry != null,
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration:
                                    _inputDecoration("City", Icons.location_city),
                              ),
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              onChanged: (val) => setState(() => selectedCity = val),
                              validator: (value) => value == null ? "Please select a city" : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              onChanged: checkPasswordStrength,
                              decoration: _inputDecoration("Password", Icons.lock).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() => obscurePassword = !obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) => value!.length < 6 ? "Min 6 characters required" : null,
                            ),
                            if (passwordStrengthText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: passwordStrength,
                                        color: passwordStrengthColor,
                                        backgroundColor: Colors.grey[300],
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(passwordStrengthText,
                                        style: TextStyle(color: passwordStrengthColor)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: agreedToTerms,
                                  onChanged: (val) => setState(() => agreedToTerms = val ?? false),
                                ),
                                const Expanded(
                                  child: Text("I agree to the Terms & Conditions",
                                      style: TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: isLoading ? null : () => handleSignup(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text("Sign Up",
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }
}
