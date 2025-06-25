import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../utils/api.dart';

class AuthService {
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$authUrl/login'),  
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setString('user_uid', data['user']['uid']);
        await prefs.setString('user_email', data['user']['email']);

        return true;
      } else {
        print('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login exception: $e');
      return false;
    }
  }

  Future<bool> signup({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String city,
    required String country,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$authUrl/signup'),  
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": username,
          "email": email,
          "first_name": firstName,
          "last_name": lastName,
          "city": city,
          "country": country,
          "phone": phone,
          "password": password,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Signup failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Signup exception: $e');
      return false;
    }
  }

  Future<http.Response> signupWithResponse({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String city,
    required String country,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$authUrl/signup'),  
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": username,
        "email": email,
        "first_name": firstName,
        "last_name": lastName,
        "city": city,
        "country": country,
        "phone": phone,
        "password": password,
      }),
    );
    return response;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  Future<bool> sendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$authUrl/forgot-password'),  
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$authUrl/verify-otp'),  
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return response.statusCode == 200;
  }

  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('$authUrl/reset-password'),  
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }),
    );
    return response.statusCode == 200;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>?> getTokenData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      try {
        return Jwt.parseJwt(token);
      } catch (e) {
        print('JWT decode error: $e');
        return null;
      }
    }
    return null;
  }

  Future<bool> refreshAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.get(
        Uri.parse('$authUrl/refresh_token'),  
        headers: {'Authorization': 'Bearer $refreshToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        
        if (data.containsKey('access_token')) {
          await prefs.setString('access_token', data['access_token']);
        }

        
        if (data.containsKey('refresh_token')) {
          await prefs.setString('refresh_token', data['refresh_token']);
        }

        return true;
      } else {
        await logout();
        return false;
      }
    } catch (e) {
      print("Refresh token failed: $e");
      await logout();
      return false;
    }
  }

  Future<bool> guestLogin() async {
  try {
    final response = await http.post(
      Uri.parse('$authUrl/guest-login'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('access_token', data['access_token']);
      await prefs.setString('refresh_token', data['refresh_token'] ?? '');
      await prefs.setString('user_uid', data['user']['uid']);
      await prefs.setString(
        'user_email',
        data['user']['email'] ?? 'guest@example.com',
      );

      
      await prefs.setBool('is_guest', data['user']['guest'] ?? false);

      return true;
    } else {
      print('Guest login failed: ${response.body}');
      return false;
    }
  } catch (e) {
    print('Guest login exception: $e');
    return false;
  }
}

}
