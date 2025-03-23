// lib/screens/join_room_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tourgather_trial/services/auth_service.dart';
import 'package:tourgather_trial/services/room_service.dart';
import 'package:tourgather_trial/screens/map_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  final String roomId;
  
  const JoinRoomScreen({super.key, required this.roomId});

  @override
  _JoinRoomScreenState createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final RoomService _roomService = RoomService();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter room password'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String userId = authService.currentUser!.uid;
      
      bool success = await _roomService.joinRoom(
        widget.roomId,
        _passwordController.text.trim(),
        userId,
      );
      
      if (mounted) {
        if (success) {
          // Navigate to map screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(roomId: widget.roomId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password or room not found'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the room password to join',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Room Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinRoom,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Join Room', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
