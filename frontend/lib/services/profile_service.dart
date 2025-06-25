import 'dart:convert';
import '../utils/api.dart';
import 'authorized_request.dart';

class ProfileService {
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await authorizedRequest(
        endpoint: '/auth/profile',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Failed to fetch profile: ${response.body}");
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }

    return null;
  }

  Future<bool> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      final response = await authorizedRequest(
        endpoint: '/auth/profile',
        method: 'PUT',
        body: updatedData,
      );

      print("Update profile response: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("Update profile error: $e");
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await authorizedRequest(
        endpoint: '/auth/change-password',
        method: 'PUT',
        body: {
          "old_password": oldPassword,
          "new_password": newPassword,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Failed to change password: $e");
      return false;
    }
  }
}

