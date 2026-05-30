import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SecurityDeviceModel {
  final int deviceId;
  final String deviceType; // door_lock, window_sensor, motion_sensor, camera
  final String name;
  final String? location;
  final String? classroomName;
  final int? classroomId;
  final String status; // secured, breached, offline
  final bool isActive;
  final DateTime lastUpdated;

  SecurityDeviceModel({
    required this.deviceId,
    required this.deviceType,
    required this.name,
    this.location,
    this.classroomName,
    this.classroomId,
    required this.status,
    required this.isActive,
    required this.lastUpdated,
  });

  factory SecurityDeviceModel.fromJson(Map<String, dynamic> json) {
    return SecurityDeviceModel(
      deviceId: json['device_id'],
      deviceType: json['device_type'],
      name: json['name'] ?? 'Security Device',
      location: json['location'],
      classroomName: json['classroom_name'],
      classroomId: json['classroom_id'],
      status: json['status'] ?? 'offline',
      isActive: json['is_active'] ?? false,
      lastUpdated: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  IconData get deviceIcon {
    switch (deviceType.toLowerCase()) {
      case 'door_lock':
        return status == 'secured' ? Icons.lock : Icons.lock_open;
      case 'window_sensor':
        return status == 'secured' ? Icons.sensor_window : Icons.sensor_window_outlined;
      case 'motion_sensor':
        return Icons.motion_photos_on;
      case 'camera':
        return Icons.videocam;
      default:
        return Icons.security;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'secured':
        return Colors.green;
      case 'breached':
        return Colors.red;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'secured':
        return 'Secured';
      case 'breached':
        return 'Breached';
      case 'offline':
        return 'Offline';
      default:
        return status;
    }
  }
}