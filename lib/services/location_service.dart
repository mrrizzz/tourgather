// lib/services/location_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GeolocatorPlatform _geolocator = GeolocatorPlatform.instance;

  // Request permission
  Future<bool> requestPermission() async {
    LocationPermission permission = await _geolocator.requestPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Get current position
  Future<Position> getCurrentPosition() async {
    return await _geolocator.getCurrentPosition();
  }

  // Get position stream
  Stream<Position> getPositionStream() {
    return _geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      )
    );
  }

  // Update user location in a room
  Future<void> updateLocation(String roomId, String userId, double lat, double lng) {
    return _database.ref('locations/$roomId/$userId').set({
      'latitude': lat,
      'longitude': lng,
      'timestamp': ServerValue.timestamp,
    });
  }

  // Get all locations in a room
  Stream<DatabaseEvent> getRoomLocations(String roomId) {
    return _database.ref('locations/$roomId').onValue;
  }
}