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
              "Hello! I'm your database assistant 🤖\n\nI can help you explore:\n\n✨ Users and profiles\n📅 Events and schedules\n⭐ Ratings and responses\n\nJust ask me anything about the data!",
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
      buffer.writeln("🎯 Found ${data.length} result(s):\n");
    }

    // Show all results instead of limiting to 10
    for (int i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;
      buffer.writeln("${i + 1}. ${_formatItem(item)}");
      if (i < data.length - 1) buffer.writeln();
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
          duration: const Duration(milliseconds: 500), // Smoother, slightly longer animation
          curve: Curves.easeOutCubic, // More elegant easing curve
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
        ? const Color(0xFF0A0A0F)  // Deep midnight blue
        : const Color(0xFFF5F7FA),  // Sophisticated light blue-grey
      appBar: AppBar(
        title: const Text('Database Assistant'),
        backgroundColor: isDark 
          ? const Color(0xFF1A1B23)
          : Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                ? [const Color(0xFF1A1B23), const Color(0xFF0E0F17)]
                : [const Color(0xFF4DD0E1), const Color(0xFF42A5F5)], // Match the new teal-blue theme
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
              ? [
                  const Color(0xFF1E1E2F),  // Elegant dark purple-blue
                  const Color(0xFF252538),  // Slightly warmer dark background
                ]
              : [
                  const Color(0xFFF8FAFC),  // Pure light grey-blue
                  const Color(0xFFEEF4F7),  // Soft blue-tinted background
                ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(
                    message: _messages[index], 
                    index: index,
                  );
                },
              ),
            ),
            if (_isLoading)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                            ? [const Color(0xFF5E6C8A), const Color(0xFF7B88A8)] // Match assistant avatar
                            : [const Color(0xFF42A5F5), const Color(0xFF7986CB)], // Match assistant avatar
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark 
                            ? const Color(0xFF2F354D).withOpacity(0.8)  // Match assistant bubble color
                            : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isDark 
                                ? Colors.black.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Assistant is thinking',
                              style: TextStyle(
                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                  ? const Color(0xFF1F2937).withOpacity(0.85)  // Elegant dark slate
                  : const Color(0xFFFEFEFE).withOpacity(0.95), // Pure white with transparency
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark 
                    ? const Color(0xFF374151).withOpacity(0.6)   // Sophisticated dark border
                    : const Color(0xFFE5E7EB).withOpacity(0.8),  // Light elegant border
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : const Color(0xFF6366F1).withOpacity(0.08), // Subtle indigo shadow
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask me anything about your data...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isLoading,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isLoading ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: _isLoading 
                            ? null
                            : LinearGradient(
                                colors: isDark
                                  ? [const Color(0xFF5E6C8A), const Color(0xFF7B88A8)] // Dark mode: muted blue-gray
                                  : [const Color(0xFF4DD0E1), const Color(0xFF42A5F5)], // Light mode: teal to blue
                              ),
                          color: _isLoading 
                            ? (isDark ? Colors.grey.shade700 : Colors.grey.shade300)
                            : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isLoading 
                            ? null
                            : [
                                BoxShadow(
                                  color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : const Color(0xFF4DD0E1).withOpacity(0.3), // Match new teal theme
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final int index;

  const ChatBubble({Key? key, required this.message, this.index = 0}) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Add smooth animations for both user and assistant messages
    _animationController = AnimationController(
      duration: Duration(milliseconds: widget.message.isUser ? 400 : 600 + (widget.index * 100)),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.message.isUser 
        ? const Offset(0.3, 0)  // User messages slide from right
        : const Offset(0, 0.3), // Assistant messages slide from bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ));

    // Start animation with a slight delay for smoother appearance
    Future.delayed(Duration(milliseconds: widget.message.isUser ? 50 : 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget bubbleContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            widget.message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.message.isUser) ...[
            _buildAvatar(isDark, false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: _getMessageGradient(isDark),
                  borderRadius: _getBorderRadius(),
                  boxShadow: _getBoxShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.isUser)
                      _buildUserMessage(isDark)
                    else
                      _buildAssistantMessage(isDark),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: _getTimeColor(isDark),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(widget.message.timestamp),
                          style: TextStyle(
                            color: _getTimeColor(isDark),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(isDark, true),
          ],
        ],
      ),
    );

    // Apply animations to both user and assistant messages
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: bubbleContent,
        ),
      ),
    );
  }

  Widget _buildUserMessage(bool isDark) {
    return Text(
      widget.message.text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildAssistantMessage(bool isDark) {
    // Check if this message contains structured data
    final hasData = widget.message.data != null && widget.message.data!.isNotEmpty;
    
    if (hasData) {
      return _buildDataContent(isDark);
    } else {
      return _buildSimpleTextContent(isDark);
    }
  }

  Widget _buildDataContent(bool isDark) {
    final parts = widget.message.text.split('\n');
    final header = parts.isNotEmpty ? parts[0] : '';
    final hasResults = widget.message.data!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                hasResults ? Icons.check_circle_rounded : Icons.info_rounded,
                size: 16,
                color: hasResults 
                  ? (isDark ? Colors.green.shade300 : Colors.green.shade600)
                  : (isDark ? Colors.blue.shade300 : Colors.blue.shade600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  header,
                  style: TextStyle(
                    color: _getTextColor(isDark),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        
        if (hasResults) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark 
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Results (${widget.message.data!.length})",
                  style: TextStyle(
                    color: _getTextColor(isDark).withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Show all results
                ...widget.message.data!.map<Widget>((item) => 
                  _buildDataItem(item as Map<String, dynamic>, isDark)
                ).toList(),
              ],
            ),
          ),
        ] else ...[
          Text(
            widget.message.text,
            style: TextStyle(
              color: _getTextColor(isDark),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataItem(Map<String, dynamic> item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.white.withOpacity(0.02)
          : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: item.entries.map<Widget>((entry) {
          final key = _formatKey(entry.key);
          final value = _formatValue(entry.value);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    "$key:",
                    style: TextStyle(
                      color: _getTextColor(isDark).withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: _getTextColor(isDark),
                      fontSize: 12,
                      fontFamily: _isSpecialField(entry.key) ? 'monospace' : null,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSimpleTextContent(bool isDark) {
    return Text(
      widget.message.text,
      style: TextStyle(
        color: _getTextColor(isDark),
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    
    final stringValue = value.toString();
    
    // Format datetime fields
    if (stringValue.contains('T') && stringValue.contains('Z')) {
      try {
        final dateTime = DateTime.parse(stringValue);
        return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        return stringValue;
      }
    }
    
    // Format boolean values
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    
    return stringValue;
  }

  bool _isSpecialField(String key) {
    return key.toLowerCase().contains('id') || 
            key.toLowerCase().contains('hash') ||
            key.toLowerCase().contains('url');
  }

  Widget _buildAvatar(bool isDark, bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: isUser
          ? LinearGradient(
              colors: isDark
                ? [const Color(0xFF4A90A4), const Color(0xFF5BA4B0)] // Dark mode: muted teal
                : [const Color(0xFF4DD0E1), const Color(0xFF26C6DA)], // Light mode: soft teal gradient
            )
          : LinearGradient(
              colors: isDark
                ? [const Color(0xFF5E6C8A), const Color(0xFF7B88A8)] // Dark mode: muted blue-gray
                : [const Color(0xFF42A5F5), const Color(0xFF7986CB)], // Light mode: refined blue to indigo
            ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
              ? Colors.black.withOpacity(0.4)
              : (isUser 
                  ? const Color(0xFF4DD0E1).withOpacity(0.3)
                  : const Color(0xFF42A5F5).withOpacity(0.3)),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  LinearGradient _getMessageGradient(bool isDark) {
    if (widget.message.isUser) {
      // Elegant soft pastel gradient for user messages
      return LinearGradient(
        colors: isDark 
          ? [const Color(0xFF1A2A3C), const Color(0xFF243447)] // Dark mode: elegant dark blue
          : [const Color(0xFF80DEEA), const Color(0xFFB2EBF2)], // Light mode: soft teal to cyan pastel
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (widget.message.isError) {
      return LinearGradient(
        colors: isDark 
          ? [const Color(0xFF2D1B1B), const Color(0xFF3D2222)] // Dark mode: elegant dark red
          : [const Color(0xFFFFEBEE), const Color(0xFFFCE4EC)], // Light mode: soft rose
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Assistant messages: subtle pastels in light mode, elegant dark tones in dark mode
      return LinearGradient(
        colors: isDark 
          ? [const Color(0xFF2A2F3D), const Color(0xFF343B4A)] // Dark mode: muted dark backgrounds
          : [const Color(0xFFE8F5E9), const Color(0xFFE3F2FD)], // Light mode: soft mint to pastel blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  BorderRadius _getBorderRadius() {
    const radius = Radius.circular(18);
    if (widget.message.isUser) {
      return const BorderRadius.only(
        topLeft: radius,
        topRight: Radius.circular(6),
        bottomLeft: radius,
        bottomRight: radius,
      );
    } else {
      return const BorderRadius.only(
        topLeft: Radius.circular(6),
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      );
    }
  }

  List<BoxShadow> _getBoxShadow(bool isDark) {
    if (widget.message.isUser) {
      return [
        BoxShadow(
          color: isDark
            ? Colors.black.withOpacity(0.4)
            : const Color(0xFF4DD0E1).withOpacity(0.25), // Soft teal shadow for new user colors
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];
    }

    // Enhanced shadows for assistant messages
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
    } else {
      // Soft shadows for light mode
      if (widget.message.isError) {
        return [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        return [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.15), // Soft blue shadow for assistant
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ];
      }
    }
  }

  Color _getTextColor(bool isDark) {
    if (widget.message.isUser) {
      return isDark ? Colors.white : const Color(0xFF1A2A3C); // Dark text on light pastel, white on dark
    }

    if (widget.message.isError) {
      return isDark ? Colors.red.shade200 : Colors.red.shade800;
    } else {
      return isDark ? Colors.grey.shade100 : const Color(0xFF37474F); // Better contrast with new assistant colors
    }
  }

  Color _getTimeColor(bool isDark) {
    if (widget.message.isUser) {
      return isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF1A2A3C).withOpacity(0.7);
    }

    if (widget.message.isError) {
      return isDark ? Colors.red.shade300 : Colors.red.shade700;
    } else {
      return isDark ? Colors.grey.shade300 : const Color(0xFF546E7A); // Better contrast for time stamps
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}