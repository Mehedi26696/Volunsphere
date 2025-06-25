import 'dart:convert';
import 'authorized_request.dart';
import '../utils/api.dart';

class LeaderboardService {
   
  static Future<List<dynamic>> fetchLeaderboard(String sortBy) async {
    try {
      final response = await authorizedRequest(
        endpoint: '/leaderboard/?sort_by=$sortBy',  
          
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        String message = 'Failed to load leaderboard';
        try {
          final jsonBody = jsonDecode(response.body);
          if (jsonBody is Map && jsonBody.containsKey('detail')) {
            message += ': ${jsonBody['detail']}';
          }
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Error fetching leaderboard: $e');
    }
  }
}

