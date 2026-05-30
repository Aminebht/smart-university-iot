import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/room_model.dart';
import '../../../services/supabase_service.dart';
import 'room_detail_screen.dart';

class RoomListScreen extends StatefulWidget {
  const RoomListScreen({super.key});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final data = await SupabaseService.getRooms();
    setState(() {
      _rooms = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRooms,
              child: ListView.builder(
                itemCount: _rooms.length,
                itemBuilder: (context, index) {
                  final room = RoomModel.fromJson(_rooms[index]);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.meeting_room, color: AppColors.primary),
                      title: Text(room.name),
                      subtitle: Text('Capacity: ${room.capacity}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailScreen(roomId: room.roomId),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
