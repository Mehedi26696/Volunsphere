import 'dart:convert';
import '../utils/api.dart';
import 'authorized_request.dart';

class UserService {
  /// Fetch all user IDs from the backend
  static Future<List<String>> getAllUserIds() async {
    try {
      final response = await authorizedRequest(
        endpoint:
            '/users/all-ids', // Make sure your backend supports this endpoint
        method: 'GET',
      );
      if (response.statusCode == 200) {
        final List<dynamic> ids = jsonDecode(response.body);
        return ids.cast<String>();
      } else {
        print(
          'Failed to fetch user IDs: \\${response.statusCode} - \\${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching user IDs: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final response = await authorizedRequest(
        endpoint: '/users/stats',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print(
          "Failed to fetch user stats: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Error fetching user stats: $e");
    }
    return null;
  }
}
