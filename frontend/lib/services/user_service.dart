import 'dart:convert';
import '../utils/api.dart';
import 'authorized_request.dart';

class UserService {
  
  static Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final response = await authorizedRequest(
        endpoint: '/users/stats',   
        method: 'GET',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Failed to fetch user stats: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching user stats: $e");
    }
    return null;
  }
}

