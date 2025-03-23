// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tourgather_trial/services/location_service.dart';
import 'package:tourgather_trial/services/alert_service.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  final String roomId;
  
  const MapScreen({super.key, required this.roomId});
  
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final AlertService _alertService = AlertService();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  late StreamSubscription<Position> _positionSubscription;
  late StreamSubscription<DatabaseEvent> _locationsSubscription;
  late StreamSubscription<DatabaseEvent> _alertsSubscription;
  bool _isMapReady = false;
  
  @override
  void initState() {
    super.initState();
    _initLocation();
  }
  
  @override
  void dispose() {
    _positionSubscription.cancel();
    _locationsSubscription.cancel();
    _alertsSubscription.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _initLocation() async {
    bool hasPermission = await _locationService.requestPermission();
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied'))
        );
      }
      return;
    }
    
    try {
      _currentPosition = await _locationService.getCurrentPosition();
      
      if (mounted) {
        setState(() {});
        _startLocationUpdates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}'))
        );
      }
    }
  }
  
  void _startLocationUpdates() {
    // Listen to own location changes
    _positionSubscription = _locationService.getPositionStream().listen((Position position) {
      _currentPosition = position;
      
      if (_isMapReady) {
        // Update own location in Firebase
        String userId = FirebaseAuth.instance.currentUser!.uid;
        _locationService.updateLocation(
          widget.roomId, 
          userId, 
          position.latitude, 
          position.longitude
        );
      }
      
      setState(() {});
    });
    
    // Listen to all locations in the room
    _locationsSubscription = _locationService.getRoomLocations(widget.roomId).listen((event) {
      if (event.snapshot.value != null) {
        final locations = event.snapshot.value as Map<dynamic, dynamic>;
        
        setState(() {
          _markers.clear();
          
          locations.forEach((userId, locationData) {
            final data = locationData as Map<dynamic, dynamic>;
            final lat = data['latitude'] as double;
            final lng = data['longitude'] as double;
            
            _markers.add(
              Marker(
                markerId: MarkerId(userId),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  userId == FirebaseAuth.instance.currentUser!.uid 
                      ? BitmapDescriptor.hueBlue 
                      : BitmapDescriptor.hueRed
                ),
                infoWindow: InfoWindow(
                  title: userId == FirebaseAuth.instance.currentUser!.uid 
                      ? 'You' 
                      : 'User $userId',
                ),
              ),
            );
          });
        });
      }
    });
    
    // Listen to alerts in the room
    _alertsSubscription = _alertService.getRoomAlerts(widget.roomId).listen((event) {
      if (event.snapshot.value != null) {
        final alerts = event.snapshot.value as Map<dynamic, dynamic>;
        
        setState(() {
          // Keep user markers but remove old alert markers
          _markers.removeWhere((marker) => marker.markerId.value.startsWith('alert_'));
          
          alerts.forEach((alertId, alertData) {
            final data = alertData as Map<dynamic, dynamic>;
            if (data['resolved'] == false) {
              final lat = data['latitude'] as double;
              final lng = data['longitude'] as double;
              final type = data['type'] as String;
              final userId = data['userId'] as String;
              
              _markers.add(
                Marker(
                  markerId: MarkerId('alert_$alertId'),
                  position: LatLng(lat, lng),
                  icon: _getAlertIcon(type),
                  infoWindow: InfoWindow(
                    title: _getAlertTitle(type),
                    snippet: userId == FirebaseAuth.instance.currentUser!.uid 
                        ? 'Your alert' 
                        : 'From user $userId',
                  ),
                  onTap: () {
                    _showAlertDialog(alertId, type, userId);
                  },
                ),
              );
            }
          });
        });
      }
    });
  }
  
  BitmapDescriptor _getAlertIcon(String type) {
    switch (type) {
      case 'fuel':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      case 'tire':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      case 'health':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
  
  String _getAlertTitle(String type) {
    switch (type) {
      case 'fuel':
        return 'Bensin Habis';
      case 'tire':
        return 'Ban Bocor';
      case 'health':
        return 'Darurat Kesehatan';
      default:
        return 'Darurat';
    }
  }
  
  void _showAlertDialog(String alertId, String type, String userId) {
    if (userId == FirebaseAuth.instance.currentUser!.uid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_getAlertTitle(type)),
          content: const Text('Do you want to resolve this alert?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _alertService.resolveAlert(widget.roomId, alertId);
                Navigator.pop(context);
              },
              child: const Text('Resolve'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_getAlertTitle(type)),
          content: const Text('A member of your tour group needs assistance.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  
  void _sendAlert(String type) {
    if (_currentPosition != null) {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      _alertService.sendAlert(
        widget.roomId,
        userId,
        type,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getAlertTitle(type)} alert sent'))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available'))
      );
    }
  }
  
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _isMapReady = true;
    });
    
    if (_currentPosition != null) {
      // Update initial location in Firebase
      String userId = FirebaseAuth.instance.currentUser!.uid;
      _locationService.updateLocation(
        widget.roomId, 
        userId, 
        _currentPosition!.latitude, 
        _currentPosition!.longitude
      );
      
      // Move camera to current position
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }
  
  void _centerMapOnUser() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              // TODO: Show room members list
            },
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: false,
                  markers: _markers,
                  onMapCreated: _onMapCreated,
                ),
                Positioned(
                  bottom: 90,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'centerMap',
                    mini: true,
                    onPressed: _centerMapOnUser,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
      floatingActionButton: _currentPosition == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.local_gas_station, color: Colors.yellow[700]),
                          title: const Text('Bensin Habis'),
                          onTap: () {
                            Navigator.pop(context);
                            _sendAlert('fuel');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.tire_repair, color: Colors.orange),
                          title: const Text('Ban Bocor'),
                          onTap: () {
                            Navigator.pop(context);
                            _sendAlert('tire');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.medical_services, color: Colors.purple),
                          title: const Text('Darurat Kesehatan'),
                          onTap: () {
                            Navigator.pop(context);
                            _sendAlert('health');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.warning_amber),
              label: const Text('Send Alert'),
            ),
    );
  }
}