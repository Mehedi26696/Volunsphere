import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../models/event_model.dart';
import '../utils/api.dart';
import '../services/auth_service.dart';

class EventsService {
  static Future<http.Response> authorizedRequest({
    required String endpoint,
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
    String? base,
  }) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('No access token available');
    }

    final baseUrlToUse = base ?? baseUrl;
    final url = Uri.parse('$baseUrlToUse$endpoint');

    final Map<String, String> reqHeaders = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };

    late http.Response response;

    switch (method.toUpperCase()) {
      case 'POST':
        response = await http.post(url, headers: reqHeaders, body: body);
        break;
      case 'PUT':
        response = await http.put(url, headers: reqHeaders, body: body);
        break;
      case 'PATCH':
        response = await http.patch(url, headers: reqHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(url, headers: reqHeaders);
        break;
      case 'GET':
      default:
        response = await http.get(url, headers: reqHeaders);
    }

    return response;
  }

  static Future<Event> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime startDatetime,
    required DateTime endDatetime,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
  }) async {
    final body = jsonEncode({
      'title': title,
      'description': description,
      'location': location,
      'start_datetime': startDatetime.toUtc().toIso8601String(),
      'end_datetime': endDatetime.toUtc().toIso8601String(),
      'image_urls': imageUrls ?? [],
      'latitude': latitude,
      'longitude': longitude,
    });

    final response = await authorizedRequest(
      endpoint: '/create',
      method: 'POST',
      body: body,
      base: eventUrl,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create event: ${response.body}');
    }

    final eventJson = jsonDecode(response.body);
    return Event.fromJson(eventJson);
  }

  static Future<List<String>> uploadEventImages(
    String eventId,
    List<File> files,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    final uri = Uri.parse('$eventUrl/upload-event-images/?event_id=$eventId');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    for (var file in files) {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          file.path,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final decoded = jsonDecode(respStr);
      return List<String>.from(decoded['image_urls']);
    } else {
      throw Exception('Image upload failed with status ${response.statusCode}');
    }
  }

  static Future<List<Event>> getMyEvents() async {
    final response = await authorizedRequest(
      endpoint: '/my',
      method: 'GET',
      base: eventUrl,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch my events: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Event.fromJson(e)).toList();
  }

  static Future<List<Event>> getAllEvents() async {
    final url = Uri.parse('$eventUrl/all');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch all events: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Event.fromJson(e)).toList();
  }

  static Future<Event?> getEventById(String eventId) async {
    final response = await authorizedRequest(
      endpoint: '/$eventId',
      method: 'GET',
      base: eventUrl,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Event.fromJson(json);
    } else {
      return null;
    }
  }

  static Future<bool> deleteEvent(String eventId) async {
    final response = await authorizedRequest(
      endpoint: '/$eventId',
      method: 'DELETE',
      base: eventUrl,
    );
    return response.statusCode == 200;
  }

  static Future<bool> updateEvent(
    String eventId,
    Event updatedEvent, {
    List<String>? imageUrls,
  }) async {
    final body = jsonEncode({
      'title': updatedEvent.title,
      'description': updatedEvent.description,
      'location': updatedEvent.location,
      'start_datetime': updatedEvent.startDatetime.toUtc().toIso8601String(),
      'end_datetime': updatedEvent.endDatetime.toUtc().toIso8601String(),
      'image_urls': imageUrls ?? updatedEvent.imageUrls ?? [],
      'latitude': updatedEvent.latitude,
      'longitude': updatedEvent.longitude,
    });

    final response = await authorizedRequest(
      endpoint: '/$eventId',
      method: 'PUT',
      body: body,
      base: eventUrl,
    );

    return response.statusCode == 200;
  }

  static Future<bool> joinEvent(String eventId) async {
    final response = await authorizedRequest(
      endpoint: '/$eventId/join',
      method: 'POST',
      base: eventUrl,
    );

    return response.statusCode == 201;
  }

  static Future<bool> leaveEvent(String eventId) async {
    final response = await authorizedRequest(
      endpoint: '/$eventId/leave',
      method: 'POST',
      base: eventUrl,
    );

    return response.statusCode == 200;
  }

  static Future<int> getAttendeesCount(String eventId) async {
    final url = Uri.parse('$eventUrl/$eventId/attendees/count');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return int.parse(response.body);
    } else {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getEventAttendees(
    String eventId,
  ) async {
    final response = await authorizedRequest(
      endpoint: '/$eventId/attendees',
      method: 'GET',
      base: eventUrl,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body).cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch attendees: ${response.body}');
    }
  }

  static Future<bool> updateEventResponse({
    required String eventId,
    required String userId,
    required double workTimeHours,
    required int rating,
  }) async {
    final body = jsonEncode({
      'work_time_hours': workTimeHours,
      'rating': rating,
    });

    final response = await authorizedRequest(
      endpoint: '/$eventId/responses/$userId',
      method: 'PATCH',
      body: body,
      base: eventUrl,
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    final response = await authorizedRequest(
      endpoint: '/$userId',
      method: 'GET',
      base: userUrl,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getEventResponse({
    required String eventId,
    required String userId,
  }) async {
    final response = await authorizedRequest(
      endpoint: '/$eventId/responses/$userId',
      method: 'GET',
      base: eventUrl,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      return null;
    }
  }
}
