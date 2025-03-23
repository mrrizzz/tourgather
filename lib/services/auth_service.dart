import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in anonymously
  Future<UserCredential> signInAnonymously(String displayName) async {
    UserCredential result = await _auth.signInAnonymously();
    
    // Update display name
    await result.user?.updateDisplayName(displayName);
    
    // Create user document in Firestore
    await _firestore.collection('users').doc(result.user?.uid).set({
      'name': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return result;
  }

  // Sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }
}