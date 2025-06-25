class User {
  final String uid;
  final String username;
  final String? profileImageUrl;

  User({required this.uid, required this.username, this.profileImageUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      username: json['username'],
      profileImageUrl: json['profile_image_url'],
    );
  }
}
