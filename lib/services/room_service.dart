import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new room
  Future<String> createRoom(String creatorId, String roomName, String password) async {
    final docRef = await _firestore.collection('rooms').add({
      'name': roomName,
      'password': password,
      'creatorId': creatorId,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
      'members': [creatorId]
    });
    return docRef.id;
  }

  // Join a room
  Future<bool> joinRoom(String roomId, String password, String userId) async {
    // Get room document
    DocumentSnapshot doc = await _firestore.collection('rooms').doc(roomId).get();
    
    // Check if room exists and password matches
    if (!doc.exists) {
      return false;
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    if (data['password'] != password) {
      return false;
    }
    
    // Add user to room's members
    await _firestore.collection('rooms').doc(roomId).update({
      'members': FieldValue.arrayUnion([userId])
    });
    
    return true;
  }

  // Get active rooms
  Stream<QuerySnapshot> getActiveRooms() {
    return _firestore.collection('rooms')
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // Get a specific room
  Stream<DocumentSnapshot> getRoom(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots();
  }

  // Close a room
  Future<void> closeRoom(String roomId) {
    return _firestore.collection('rooms').doc(roomId).update({
      'active': false
    });
  }
}
