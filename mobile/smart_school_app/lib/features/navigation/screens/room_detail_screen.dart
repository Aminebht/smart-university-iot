import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/actuator_model.dart';
import '../../../core/models/camera_model.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/sensor_reading_model.dart';
import '../../../services/supabase_service.dart';
import '../../camera/screens/camera_view_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  RoomModel? _room;
  bool _loading = true;
  StreamSubscription? _occupancySub;

  @override
  void initState() {
    super.initState();
    _loadRoom();
    _subscribeToOccupancy();
  }

  @override
  void dispose() {
    _occupancySub?.cancel();
    super.dispose();
  }

  void _subscribeToOccupancy() {
    _occupancySub = SupabaseService.streamOccupancyForRoom(widget.roomId).listen((_) {
      _loadRoom();
    }, onError: (_) {});
  }

  Future<void> _loadRoom() async {
    try {
      final data = await SupabaseService.getRoomDetails(widget.roomId);
      setState(() {
        _room = RoomModel.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActuator(String actuatorType, bool currentOn) async {
    await SupabaseService.toggleActuator(widget.roomId, actuatorType, !currentOn);
    await _loadRoom();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final room = _room;
    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Room')),
        body: const Center(child: Text('Room not found')),
      );
    }

    final sensorReadings = room.sensorReadings;
    final actuators = room.actuators;
    final occupancy = room.occupancyCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRoom,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Occupancy card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 40, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Occupancy', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$occupancy people', style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sensor readings
            if (sensorReadings.isNotEmpty) ...[
              const Text('Latest Sensor Readings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sensorReadings.take(6).map((r) {
                  final reading = r is SensorReadingModel ? r : SensorReadingModel.fromJson(r as Map<String, dynamic>);
                  return Chip(
                    avatar: Icon(reading.sensorIcon, color: AppColors.primary),
                    label: Text('${reading.sensorType}: ${reading.displayValue}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Actuators
            if (actuators.isNotEmpty) ...[
              const Text('Actuators', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...actuators.map((actuator) {
                return SwitchListTile(
                  title: Text(actuator.displayName),
                  subtitle: Text('State: ${actuator.currentState}'),
                  value: actuator.isOn,
                  onChanged: (_) => _toggleActuator(actuator.actuatorType, actuator.isOn),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Camera button
            if (room.hasCamera)
              ElevatedButton.icon(
                onPressed: () async {
                  final url = await SupabaseService.getStreamUrlForRoom(widget.roomId);
                  if (url != null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CameraViewScreen(
                          camera: CameraModel.fromRoomStreamUrl(widget.roomId, url),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.videocam),
                label: const Text('Open Camera Stream'),
              ),
          ],
        ),
      ),
    );
  }
}
