import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'sensor_reading_model.dart';
import 'actuator_model.dart';

class RoomModel {
  final String roomId;
  final String name;
  final int capacity;
  final String? streamWsUrl;
  final String operationalStart;
  final String operationalEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data (fetched separately)
  final List<SensorReadingModel> sensorReadings;
  final List<ActuatorModel> actuators;
  final int? occupancyCount;
  final DeviceStatus status;

  RoomModel({
    required this.roomId,
    required this.name,
    required this.capacity,
    this.streamWsUrl,
    this.operationalStart = '07:00',
    this.operationalEnd = '22:00',
    required this.createdAt,
    required this.updatedAt,
    this.sensorReadings = const [],
    this.actuators = const [],
    this.occupancyCount,
    this.status = DeviceStatus.normal,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomId: json['room_id'] ?? '',
      name: json['name'] ?? 'Unknown Room',
      capacity: json['capacity'] ?? 0,
      streamWsUrl: json['stream_ws_url'],
      operationalStart: json['operational_start'] ?? '07:00',
      operationalEnd: json['operational_end'] ?? '22:00',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      occupancyCount: json['occupancy_count'] ??
          (json['occupancy'] != null ? json['occupancy']['person_count'] : null),
      sensorReadings: (json['sensor_readings'] as List? ?? [])
          .map((e) => SensorReadingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      actuators: (json['actuators'] as List? ?? [])
          .map((e) => ActuatorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'name': name,
      'capacity': capacity,
      'stream_ws_url': streamWsUrl,
      'operational_start': operationalStart,
      'operational_end': operationalEnd,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SensorReadingModel? getLatestReading(String sensorType) {
    final filtered = sensorReadings
        .where((r) => r.sensorType == sensorType)
        .toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.first;
  }

  bool get hasCamera => streamWsUrl != null && streamWsUrl!.isNotEmpty;

  Color get statusColor {
    switch (status) {
      case DeviceStatus.normal:
        return AppColors.success;
      case DeviceStatus.warning:
        return AppColors.warning;
      case DeviceStatus.critical:
        return AppColors.error;
      case DeviceStatus.offline:
        return AppColors.error;
      case DeviceStatus.maintenance:
        return AppColors.warning;
      case DeviceStatus.online:
        return AppColors.success;
    }
  }

  bool get isOperational {
    final now = DateTime.now();
    final parts = operationalStart.split(':');
    final start = DateTime(now.year, now.month, now.day,
        int.parse(parts[0]), int.parse(parts[1]));
    final endParts = operationalEnd.split(':');
    final end = DateTime(now.year, now.month, now.day,
        int.parse(endParts[0]), int.parse(endParts[1]));
    return now.isAfter(start) && now.isBefore(end);
  }
}
