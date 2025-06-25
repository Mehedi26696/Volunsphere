import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../main.dart';  
import 'auth_service.dart';
import '../utils/api.dart';  

 
Future<http.Response> authorizedRequest({
  required String endpoint,           
  String method = 'GET',
  Map<String, String>? headers,
  dynamic body,
  Map<String, dynamic>? queryParams,
}) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('access_token');

  headers ??= {};
  headers['Authorization'] = 'Bearer $token';
  headers['Content-Type'] = 'application/json';

  Uri uri = Uri.parse('$baseUrl$endpoint');

 
  if (queryParams != null && queryParams.isNotEmpty) {
    uri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...queryParams.map((key, value) => MapEntry(key, value.toString())),
    });
  }

   
  http.Response response = await _sendRequest(uri, method, headers, body);

   
  if (response.statusCode == 401) {
    final refreshed = await AuthService().refreshAccessToken();
    if (refreshed) {
      final newToken = prefs.getString('access_token');
      headers['Authorization'] = 'Bearer $newToken';
      response = await _sendRequest(uri, method, headers, body);
    } else {
      _showSessionExpiredDialog();
      throw Exception("Session expired");
    }
  }

  return response;
}

Future<http.Response> _sendRequest(
  Uri uri,
  String method,
  Map<String, String> headers,
  dynamic body,
) {
  switch (method.toUpperCase()) {
    case 'POST':
      return http.post(uri, headers: headers, body: jsonEncode(body));
    case 'PUT':
      return http.put(uri, headers: headers, body: jsonEncode(body));
    case 'PATCH':
      return http.patch(uri, headers: headers, body: jsonEncode(body));
    case 'DELETE':
      return http.delete(uri, headers: headers);
    case 'GET':
    default:
      return http.get(uri, headers: headers);
  }
}

void _showSessionExpiredDialog() {
  final ctx = navigatorKey.currentContext!;
  showDialog(
    context: ctx,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text("Session Expired"),
      content: const Text(
        "Your session has expired. Please log in again to continue.",
      ),
      actions: [
        TextButton(
          onPressed: () {
            AuthService().logout();
            Navigator.pushNamedAndRemoveUntil(
              ctx,
              '/login',
              (route) => false,
            );
          },
          child: const Text("OK"),
        ),
      ],
    ),
  );
}
