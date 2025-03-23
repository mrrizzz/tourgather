// lib/models/room.dart
class RoomModel {
  final String id;
  final String name;
  final String password;
  final String creatorId;
  final DateTime createdAt;
  final bool active;
  final List<String> members;

  RoomModel({
    required this.id,
    required this.name,
    required this.password,
    required this.creatorId,
    required this.createdAt,
    required this.active,
    required this.members,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      id: id,
      name: map['name'] ?? '',
      password: map['password'] ?? '',
      creatorId: map['creatorId'] ?? '',
      createdAt: map['createdAt'] != null ? 
                (map['createdAt']).toDate() : 
                DateTime.now(),
      active: map['active'] ?? true,
      members: List<String>.from(map['members'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'password': password,
      'creatorId': creatorId,
      'createdAt': createdAt,
      'active': active,
      'members': members,
    };
  }
}