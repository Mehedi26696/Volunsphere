import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post_model.dart';
import '../utils/api.dart';
import '../models/comment_model.dart';

class CommunityService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<String> _getTokenOrThrow() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception("No auth token found");
    }
    return token;
  }

  static Future<Map<String, String>> _buildHeaders({
    bool withContentType = true,
  }) async {
    final token = await _getTokenOrThrow();
    final headers = <String, String>{};
    if (withContentType) headers['Content-Type'] = 'application/json';
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<List<Post>> fetchPosts() async {
    final headers = await _buildHeaders(withContentType: false);
    final response = await http.get(
      Uri.parse('$communityUrl/posts'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Post.fromJson(item)).toList();
    } else {
      throw Exception(
        'Failed to load posts (code ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> createPost(String content) async {
    final headers = await _buildHeaders();
    final response = await http.post(
      Uri.parse('$communityUrl/posts'),
      headers: headers,
      body: jsonEncode({"content": content}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to create post (code ${response.statusCode}): ${response.body}",
      );
    }
  }

  static Future<void> likePost(String postId) async {
    final headers = await _buildHeaders(withContentType: false);
    final response = await http.post(
      Uri.parse('$communityUrl/posts/$postId/like'),
      headers: headers,
    );

    if (response.statusCode != 201) {
      throw Exception(
        "Failed to like post (code ${response.statusCode}): ${response.body}",
      );
    }
  }

  static Future<void> unlikePost(String postId) async {
    final headers = await _buildHeaders(withContentType: false);
    final response = await http.post(
      Uri.parse('$communityUrl/posts/$postId/unlike'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to unlike post (code ${response.statusCode}): ${response.body}",
      );
    }
  }

  static Future<List<Comment>> fetchComments(String postId) async {
    final headers = await _buildHeaders(withContentType: false);
    final response = await http.get(
      Uri.parse('$communityUrl/posts/$postId/comments'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Comment.fromJson(item)).toList();
    } else {
      throw Exception(
        'Failed to load comments (code ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> createComment(String postId, String content) async {
    final headers = await _buildHeaders();
    final response = await http.post(
      Uri.parse('$communityUrl/posts/$postId/comments'),
      headers: headers,
      body: jsonEncode({"content": content}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        "Failed to create comment (code ${response.statusCode}): ${response.body}",
      );
    }
  }

  static Future<void> editPost(String postId, String content) async {
    final headers = await _buildHeaders();
    final response = await http.put(
      Uri.parse('$communityUrl/posts/$postId'),
      headers: headers,
      body: jsonEncode({"content": content}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to edit post (code ${response.statusCode}): ${response.body}',
      );
    }
  }

  static Future<void> editComment(
    String postId,
    String commentId,
    String content,
  ) async {
    final headers = await _buildHeaders();
    final response = await http.put(
      Uri.parse('$communityUrl/posts/$postId/comments/$commentId'),
      headers: headers,
      body: jsonEncode({"content": content}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to edit comment (code ${response.statusCode}): ${response.body}',
      );
    }
  }
}
