import 'package:flutter/material.dart';
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

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFF626C7A),
        letterSpacing: -1,
      ),
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF626C7A), width: 1),
      ),
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
    final lastName = fullNameController.text
        .trim()
        .split(" ")
        .skip(1)
        .join(" ");

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
          const SnackBar(
            content: Text("Signup successful!"),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.pop(context);
      } else {
        final detail = json.decode(result.body)['detail'];
        String errorMessage =
            detail.toString().toLowerCase().contains('email')
                ? "Email already exists"
                : detail.toString().toLowerCase().contains('username')
                ? "Username already exists"
                : "Signup failed";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
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
    final theme = Theme.of(context);

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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                      width: 280,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Create Your Account",
                      style: TextStyle(
                        color: Color(0xFF27264A),
                        fontFamily: 'Poppins',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Sign up to start volunteering and making a difference",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w200,
                        color: const Color(0xFF6E6E86),
                        fontSize: 14,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: usernameController,
                            decoration: _buildInputDecoration(
                              "Username",
                              Icons.person,
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty ? "Username required" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: fullNameController,
                            decoration: _buildInputDecoration(
                              "Full Name",
                              Icons.badge,
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? "Full name required"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration(
                              "Email",
                              Icons.email,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return "Email required";
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value))
                                return "Enter valid email";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _buildInputDecoration(
                              "Phone",
                              Icons.phone,
                            ),
                            validator:
                                (value) =>
                                    value!.length < 6
                                        ? "Phone number too short"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                           
                          DropdownSearch<String>(
                            asyncItems: (_) async => countries,
                            selectedItem: selectedCountry,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: _buildInputDecoration(
                                "Country",
                                Icons.flag,
                              ),
                            ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search country...",
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
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
                            validator:
                                (value) =>
                                    value == null
                                        ? "Please select a country"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownSearch<String>(
                            asyncItems: (_) async => cities,
                            selectedItem: selectedCity,
                            enabled: selectedCountry != null,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: _buildInputDecoration(
                                "City",
                                Icons.location_city,
                              ),
                            ),
                            popupProps: const PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  hintText: "Search city...",
                                  prefixIcon: Icon(Icons.search),
                                ),
                              ),
                            ),
                            onChanged:
                                (val) => setState(() => selectedCity = val),
                            validator:
                                (value) =>
                                    value == null
                                        ? "Please select a city"
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            onChanged: checkPasswordStrength,
                            decoration: _buildInputDecoration(
                              "Password",
                              Icons.lock,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF9929ea),
                                ),
                                onPressed: () {
                                  setState(
                                    () => obscurePassword = !obscurePassword,
                                  );
                                },
                              ),
                            ),
                            validator:
                                (value) =>
                                    value!.length < 6
                                        ? "Min 6 characters required"
                                        : null,
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
                                  Text(
                                    passwordStrengthText,
                                    style: TextStyle(
                                      color: passwordStrengthColor,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: agreedToTerms,
                                onChanged:
                                    (val) => setState(
                                      () => agreedToTerms = val ?? false,
                                    ),
                                activeColor: const Color(0xFF9929ea),
                                tristate: false,
                                fillColor: MaterialStateProperty.all(
                                  const Color.fromARGB(255, 255, 255, 255),
                                ),
                                checkColor: const Color(0xFF9929ea),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  "I agree to the Terms & Conditions",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF626C7A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9929ea),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: const Color(
                                  0xFF9929ea,
                                ).withValues(alpha: 0.6),
                              ),
                              onPressed:
                                  isLoading
                                      ? null
                                      : () => handleSignup(context),
                              child:
                                  isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Color(0xFF626C7A),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Color(0xFF9929ea),
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
