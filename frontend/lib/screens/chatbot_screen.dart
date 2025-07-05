import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import '../utils/api.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hello! I'm your database assistant. I can help you find information about:\n\n• Users and their profiles\n• Events and event details\n• Event responses and ratings\n\nTry asking questions like:\n- 'Show me upcoming events'\n- 'List users from New York'\n- 'What are the highest rated events?'",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chatbot/query'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'question': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final success = data['success'] ?? false;
        final message = data['message'] ?? '';
        final resultData = data['data'] as List? ?? [];
        final suggestion = data['suggestion'] ?? '';

        String responseText;
        if (success && resultData.isNotEmpty) {
          responseText = _formatResponse(resultData, message);
        } else if (!success) {
          responseText =
              message.isNotEmpty
                  ? message
                  : "We cannot provide this information right now.";
          if (suggestion.isNotEmpty) {
            responseText += "\n\n💡 $suggestion";
          }
        } else {
          responseText = "No results found for your query.";
        }

        setState(() {
          _messages.add(
            ChatMessage(
              text: responseText,
              isUser: false,
              timestamp: DateTime.now(),
              data: resultData,
              isError: !success,
            ),
          );
        });
      } else {
        final error = json.decode(response.body);
        String errorText =
            "Error: ${error['detail'] ?? 'Something went wrong'}";

        // Handle new error structure from backend
        if (error['error_type'] != null) {
          errorText =
              "${error['error_type']}: ${error['error_message'] ?? 'Unknown error'}";
          if (error['suggestion'] != null &&
              error['suggestion'].toString().isNotEmpty) {
            errorText += "\n\n💡 ${error['suggestion']}";
          }
        }

        setState(() {
          _messages.add(
            ChatMessage(
              text: errorText,
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Connection error: ${e.toString()}",
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _formatResponse(List<dynamic> data, [String? customMessage]) {
    if (data.isEmpty) return "No results found.";

    final StringBuffer buffer = StringBuffer();
    if (customMessage != null && customMessage.isNotEmpty) {
      buffer.writeln("$customMessage\n");
    } else {
      buffer.writeln("Found ${data.length} result(s):\n");
    }

    for (int i = 0; i < data.length && i < 10; i++) {
      final item = data[i] as Map<String, dynamic>;
      buffer.writeln("${i + 1}. ${_formatItem(item)}");
    }

    if (data.length > 10) {
      buffer.writeln("\n... and ${data.length - 10} more results");
    }

    return buffer.toString();
  }

  String _formatItem(Map<String, dynamic> item) {
    final StringBuffer buffer = StringBuffer();
    item.forEach((key, value) {
      if (value != null) {
        // Format key to be more readable
        String formattedKey = key
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toLowerCase() + word.substring(1))
            .join(' ');
        formattedKey =
            formattedKey[0].toUpperCase() + formattedKey.substring(1);

        // Format value based on type
        String formattedValue = value.toString();
        if (key.contains('datetime') || key.contains('created_at')) {
          try {
            final dateTime = DateTime.parse(formattedValue);
            formattedValue =
                "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
          } catch (e) {
            // Keep original value if parsing fails
          }
        }

        buffer.writeln("   $formattedKey: $formattedValue");
      }
    });
    return buffer.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Assistant'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 12),
                  Text('Thinking...'),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about users, events, or responses...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<dynamic>? data;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.data,
    this.isError = false,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.smart_toy, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    message.isUser
                        ? Theme.of(context).primaryColor
                        : message.isError
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border:
                    message.isError && !message.isUser
                        ? Border.all(color: Colors.red.shade200, width: 1)
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color:
                          message.isUser
                              ? Colors.white
                              : message.isError
                              ? Colors.red.shade700
                              : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color:
                          message.isUser
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
