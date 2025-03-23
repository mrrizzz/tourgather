// lib/services/alert_service.dart
import 'package:firebase_database/firebase_database.dart';

class AlertService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Send alert
  Future<void> sendAlert(String roomId, String userId, String alertType, double lat, double lng) {
    return _database.ref('alerts/$roomId').push().set({
      'userId': userId,
      'type': alertType, // 'fuel', 'tire', 'health'
      'latitude': lat,
      'longitude': lng,
      'timestamp': ServerValue.timestamp,
      'resolved': false
    });
  }

  // Get alerts for a room
  Stream<DatabaseEvent> getRoomAlerts(String roomId) {
    return _database.ref('alerts/$roomId').onValue;
  }

  // Resolve alert
  Future<void> resolveAlert(String roomId, String alertId) {
    return _database.ref('alerts/$roomId/$alertId').update({
      'resolved': true
    });
  }
}