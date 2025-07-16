class NotificationModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'new_message'

  NotificationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'new_message',
  });

  NotificationModel copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '', // Map snake_case from backend
      eventTitle: json['event_title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      type: json['type'] ?? 'new_message',
    );
  }
}
