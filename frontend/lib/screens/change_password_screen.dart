import 'package:flutter/material.dart';
import '../services/profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _message;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await ProfileService().changePassword(
      oldPasswordController.text,
      newPasswordController.text,
    );

    setState(() {
      _isLoading = false;
      _message = result
          ? "Password changed successfully"
          : "Failed to change password";
    });
    if (result) {
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, bool obscure, VoidCallback toggleObscure) {
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
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF9929ea),
        ),
        onPressed: toggleObscure,
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
  Widget build(BuildContext context) {
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
                    ),
                    const Expanded(
                      child: Text(
                        "Change Password",
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
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9929ea).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  size: 48,
                                  color: Color(0xFF9929ea),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Update Your Password",
                                style: TextStyle(
                                  color: Color(0xFF27264A),
                                  fontFamily: 'Poppins',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Enter your current password and create a new one",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w300,
                                  color: Color(0xFF6E6E86),
                                  fontSize: 14,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: oldPasswordController,
                                decoration: _buildInputDecoration(
                                  "Current Password",
                                  Icons.lock,
                                  _obscureOld,
                                  () => setState(() => _obscureOld = !_obscureOld),
                                ),
                                obscureText: _obscureOld,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? "Enter current password"
                                        : null,
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: newPasswordController,
                                decoration: _buildInputDecoration(
                                  "New Password",
                                  Icons.lock_open,
                                  _obscureNew,
                                  () => setState(() => _obscureNew = !_obscureNew),
                                ),
                                obscureText: _obscureNew,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Enter new password";
                                  }
                                  if (value.length < 6) {
                                    return "Password must be at least 6 characters";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: confirmPasswordController,
                                decoration: _buildInputDecoration(
                                  "Confirm New Password",
                                  Icons.lock_outline,
                                  _obscureConfirm,
                                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                                obscureText: _obscureConfirm,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Confirm your new password";
                                  }
                                  if (value != newPasswordController.text) {
                                    return "Passwords do not match";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleChangePassword,
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
                                    disabledBackgroundColor: const Color(0xFF9929ea).withValues(alpha: 0.6),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Change Password",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                ),
                              ),
                              if (_message != null) ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _message == "Password changed successfully"
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.redAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _message == "Password changed successfully"
                                          ? Colors.green
                                          : Colors.redAccent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _message == "Password changed successfully"
                                            ? Icons.check_circle_outline
                                            : Icons.error_outline,
                                        color: _message == "Password changed successfully"
                                            ? Colors.green
                                            : Colors.redAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _message!,
                                          style: TextStyle(
                                            color: _message == "Password changed successfully"
                                                ? Colors.green
                                                : Colors.redAccent,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
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
