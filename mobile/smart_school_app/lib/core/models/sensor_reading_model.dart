import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SensorReadingModel {
  final int id;
  final String roomId;
  final String deviceId;
  final String sensorType;
  final double? value;
  final String? unit;
  final DateTime timestamp;
  final DateTime receivedAt;

  SensorReadingModel({
    required this.id,
    required this.roomId,
    required this.deviceId,
    required this.sensorType,
    this.value,
    this.unit,
    required this.timestamp,
    required this.receivedAt,
  });

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    return SensorReadingModel(
      id: json['id'] ?? 0,
      roomId: json['room_id'] ?? '',
      deviceId: json['device_id'] ?? 'unknown',
      sensorType: json['sensor_type'] ?? 'unknown',
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      unit: json['unit'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      receivedAt: json['received_at'] != null
          ? DateTime.parse(json['received_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'device_id': deviceId,
      'sensor_type': sensorType,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'received_at': receivedAt.toIso8601String(),
    };
  }

  String get displayValue {
    final val = value?.toStringAsFixed(1) ?? '--';
    final u = unit ?? _defaultUnit;
    return '$val $u';
  }

  int get sensorId => id;

  DeviceStatus get status {
    if (value == null) return DeviceStatus.normal;
    final v = value!;
    switch (sensorType) {
      case 'temperature':
        return v > 35 ? DeviceStatus.critical : v > 30 ? DeviceStatus.warning : DeviceStatus.normal;
      case 'humidity':
        return v > 80 ? DeviceStatus.critical : v > 60 ? DeviceStatus.warning : DeviceStatus.normal;
      case 'gas':
        return v > 1000 ? DeviceStatus.critical : v > 500 ? DeviceStatus.warning : DeviceStatus.normal;
      case 'light':
        return DeviceStatus.normal;
      default:
        return DeviceStatus.normal;
    }
  }

  Color get statusColor {
    switch (status) {
      case DeviceStatus.normal:
        return AppColors.success;
      case DeviceStatus.warning:
        return AppColors.warning;
      case DeviceStatus.critical:
        return AppColors.error;
      default:
        return AppColors.success;
    }
  }

  String get _defaultUnit {
    switch (sensorType) {
      case 'temperature': return '°C';
      case 'humidity': return '%';
      case 'gas': return 'ppm';
      case 'light': return 'lux';
      case 'distance': return 'cm';
      default: return '';
    }
  }

  IconData get sensorIcon {
    switch (sensorType) {
      case 'temperature': return Icons.thermostat;
      case 'humidity': return Icons.water_drop;
      case 'gas': return Icons.cloud;
      case 'light': return Icons.lightbulb;
      case 'distance': return Icons.social_distance;
      case 'motion': return Icons.directions_walk;
      default: return Icons.sensors;
    }
  }
}