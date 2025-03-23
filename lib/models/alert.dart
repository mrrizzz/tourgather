// lib/models/alert.dart
class AlertModel {
  final String id;
  final String userId;
  final String type;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool resolved;

  AlertModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.resolved,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map, String id) {
    return AlertModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'unknown',
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      timestamp: map['timestamp'] != null ? 
                DateTime.fromMillisecondsSinceEpoch(map['timestamp']) : 
                DateTime.now(),
      resolved: map['resolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'resolved': resolved,
    };
  }
}