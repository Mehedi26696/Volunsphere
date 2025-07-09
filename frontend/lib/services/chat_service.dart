import 'dart:async';
import 'dart:convert';
import 'package:volunsphere/utils/api.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'auth_service.dart';

class ChatService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messagesController = StreamController.broadcast();
  String? _currentEventId;
  String? _currentUserId;
  bool _isInChat = false;

  Stream<Map<String, dynamic>> get messagesStream => _messagesController.stream;

  
  Future<void> connect(String eventId) async {
    if (_channel != null) {
      print('Already connected');
      return; 
    }

    final token = await AuthService.getToken();
    if (token == null) throw Exception('No auth token found');

    // Get current user ID
    final tokenData = await AuthService.getTokenData();
    _currentUserId = tokenData?['sub'];
    _currentEventId = eventId;

    // final uri = Uri.parse('ws://192.168.54.83:8080/api/v1/chat/ws/$eventId?token=$token');
    final uri = Uri.parse('$chatUrl/ws/$eventId?token=$token');

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (data) {
        try {
          final jsonData = jsonDecode(data);
          _messagesController.add(jsonData);
        } catch (e) {
          print('Failed to decode WebSocket message: $e');
        }
      },
      onDone: () {
        print('WebSocket closed');
        // Optionally notify listeners or try to reconnect
      },
      onError: (error) {
        print('WebSocket error: $error');
        // Optionally notify listeners or try to reconnect
      },
    );
  }

  void setInChat(bool inChat) {
    _isInChat = inChat;
  }

  /// Send a raw string message through WebSocket
  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
    } else {
      print('Cannot send message: Not connected');
    }
  }

  /// Disconnect the WebSocket connection
  void disconnect() {
    _channel?.sink.close(status.normalClosure);
    _channel = null;
  }

  /// Clean up resources
  void dispose() {
    _messagesController.close();
    disconnect();
  }
}