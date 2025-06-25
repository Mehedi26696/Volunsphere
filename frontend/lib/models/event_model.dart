class Event {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final int durationMinutes;
  final double? latitude;
  final double? longitude;
  final List<String>? imageUrls;
  final String creatorId;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startDatetime,
    required this.endDatetime,
    required this.durationMinutes,
    this.latitude,
    this.longitude,
    this.imageUrls,
    required this.creatorId,
  });

  Event copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startDatetime,
    DateTime? endDatetime,
    int? durationMinutes,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    String? creatorId,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrls: (json['image_urls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      creatorId: json['creator_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'duration_minutes': durationMinutes,
      'latitude': latitude,
      'longitude': longitude,
      'image_urls': imageUrls ?? [],
      'creator_id': creatorId,
    };
  }
}
