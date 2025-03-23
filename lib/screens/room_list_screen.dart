// lib/screens/room_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tourgather_trial/models/room.dart';
import 'package:tourgather_trial/screens/login_screen.dart';
import 'package:tourgather_trial/services/auth_service.dart';
import 'package:tourgather_trial/services/room_service.dart';
import 'package:tourgather_trial/screens/create_room_screen.dart';
import 'package:tourgather_trial/screens/join_room_screen.dart';
import 'package:tourgather_trial/screens/map_screen.dart';

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final roomService = RoomService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: roomService.getActiveRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!.docs;
          
          if (rooms.isEmpty) {
            return const Center(child: Text('No active rooms found'));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = RoomModel.fromMap(
                rooms[index].data() as Map<String, dynamic>,
                rooms[index].id,
              );
              
              return ListTile(
                title: Text(room.name),
                subtitle: Text('Created: ${room.createdAt.toString().split('.')[0]}'),
                trailing: room.members.contains(authService.currentUser?.uid)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.lock),
                onTap: () {
                  if (room.members.contains(authService.currentUser?.uid)) {
                    // User is already a member, navigate to map screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(roomId: room.id),
                      ),
                    );
                  } else {
                    // User needs to join with password
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinRoomScreen(roomId: room.id),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRoomScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
