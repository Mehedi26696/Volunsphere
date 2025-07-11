import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/notification_listener_service.dart';
import '../services/missed_message_service.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String eventId;
  final List<Map<String, dynamic>> attendees;
  final Map<String, dynamic> creator;

  const ChatScreen({
    Key? key,
    required this.eventId,
    required this.attendees,
    required this.creator,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatService chatService;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];

  bool _showScrollToBottom = false;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    chatService = ChatService();

    _initChat();

    _scrollController.addListener(() {
      if (_scrollController.offset <
          _scrollController.position.maxScrollExtent - 300) {
        if (!_showScrollToBottom) {
          setState(() => _showScrollToBottom = true);
        }
      } else {
        if (_showScrollToBottom) {
          setState(() => _showScrollToBottom = false);
        }
      }
    });
  }

  Future<void> _initChat() async {
    final tokenData = await AuthService.getTokenData();
    setState(() {
      currentUserEmail = tokenData?['email'] as String?;
    });

    await chatService.connect(widget.eventId);
    chatService.setInChat(true); // Set that user is currently in chat

    // Notify listener service that user is in this chat
    NotificationListenerService.instance.addActiveChatSession(widget.eventId);

    // Mark this event as read (user is now viewing messages)
    await MissedMessageService.markEventAsRead(widget.eventId);

    chatService.messagesStream.listen((msg) {
      setState(() {
        messages.add(msg);
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    chatService.setInChat(false); // User leaving chat

    // Notify listener service that user left this chat
    NotificationListenerService.instance.removeActiveChatSession(
      widget.eventId,
    );

    chatService.dispose();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
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

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      chatService.sendMessage(text);
      _controller.clear();
      // Notify all event attendees except the sender
      final tokenData = await AuthService.getTokenData();
      final currentUserId = tokenData?['sub'];
      final attendeeIds =
          widget.attendees
              .map((a) => a['id'] as String?)
              .where((id) => id != null && id != currentUserId)
              .cast<String>()
              .toList();
      if (attendeeIds.isNotEmpty) {
        await NotificationService.instance.sendNotificationToUsers(
          userIds: attendeeIds,
          message: text,
          eventId: widget.eventId,
          eventTitle: widget.creator['username'] ?? '',
          type: 'event_message',
        );
      }
    }
  }

  Map<String, dynamic> _findSender(Map<String, dynamic> msg) {
    final email = msg['email'];
    final username = msg['username'];

    final attendee = widget.attendees.firstWhere(
      (a) =>
          (a['email'] != null && a['email'] == email) ||
          (a['username'] != null && a['username'] == username),
      orElse: () => {},
    );

    if (attendee.isEmpty &&
        widget.creator['email'] == email &&
        widget.creator['username'] == username) {
      return widget.creator;
    }

    return attendee;
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final timestamp =
        msg['timestamp'] != null ? DateTime.tryParse(msg['timestamp']) : null;

    final isMe = msg['email'] != null && msg['email'] == currentUserEmail;

    final sender = _findSender(msg);
    final profileImageUrl = sender['profile_image_url'];
    final displayName = sender['username'] ?? 'Unknown';
    final email = sender['email'] ?? '';

    final isCreator = widget.creator['email'] == email;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF9929ea).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9929ea).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                  child:
                      (profileImageUrl == null || profileImageUrl.isEmpty)
                          ? Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: const Color(0xFF9929ea),
                          )
                          : null,
                ),
              ),
            ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    isMe
                        ? const LinearGradient(
                          colors: [Color(0xFF7312ba), Color(0xFF6c3a85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.95),
                            Colors.white.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border:
                    isMe
                        ? null
                        : Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1,
                        ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isMe
                            ? const Color(0xFF9929ea).withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: isMe ? Colors.white : const Color(0xFF27264A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (isCreator) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  isMe
                                      ? [
                                        Colors.white.withValues(alpha: 0.3),
                                        Colors.white.withValues(alpha: 0.2),
                                      ]
                                      : [
                                        const Color(0xFF9929ea),
                                        const Color(0xFFB843F5),
                                      ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                isMe
                                    ? Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1,
                                    )
                                    : null,
                          ),
                          child: Text(
                            "Creator",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    msg['message'] ?? '',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isMe ? Colors.white : const Color(0xFF27264A),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color:
                            isMe
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(
                                  0xFF626C7A,
                                ).withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timestamp != null
                            ? timeago.format(timestamp.toLocal())
                            : '',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color:
                              isMe
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(
                                    0xFF626C7A,
                                  ).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF9929ea).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9929ea).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : null,
                  child:
                      (profileImageUrl == null || profileImageUrl.isEmpty)
                          ? Icon(
                            Icons.person_rounded,
                            size: 24,
                            color: const Color(0xFF9929ea),
                          )
                          : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 225, 192, 255),
              Color.fromARGB(255, 248, 250, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9929ea).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF9929ea).withValues(alpha: 0.1),
                            const Color(0xFFB843F5).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF9929ea).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF9929ea),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        "Event Chat",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF27264A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF9929ea).withValues(alpha: 0.1),
                            const Color(0xFFB843F5).withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF9929ea).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF9929ea),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (_, index) => _buildMessage(messages[index]),
                ),
              ),

              // Input Area
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.white.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9929ea).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: isPortrait ? 120 : 80,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF626C7A).withValues(alpha: 0.05),
                                const Color(0xFF626C7A).withValues(alpha: 0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(
                                0xFF626C7A,
                              ).withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: isPortrait ? 4 : 2,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              color: Color(0xFF27264A),
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Type your message...',
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF626C7A),
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9929ea), Color(0xFFB843F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF9929ea,
                              ).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded),
                          onPressed: _sendMessage,
                          color: Colors.white,
                          iconSize: 24,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.all(12),
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
      ),
      floatingActionButton:
          _showScrollToBottom
              ? Container(
                margin: const EdgeInsets.only(bottom: 100),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9929ea), Color(0xFFB843F5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9929ea).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onPressed: _scrollToBottom,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              )
              : null,
    );
  }
}
