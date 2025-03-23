// lib/models/user.dart
class UserModel {
  final String id;
  final String name;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? 'Anonymous',
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
    };
  }
}
