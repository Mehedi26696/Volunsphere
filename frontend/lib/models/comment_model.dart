class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String profileImageUrl;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      username: json['user']['username'],
      profileImageUrl: json['user']['profile_image_url'] ?? '',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
