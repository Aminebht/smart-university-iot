import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SensorReadingModel {
  final int readingId;
  final int sensorId;
  final String sensorType;
  final double value;
  final DateTime timestamp;
  final DeviceStatus status;

  SensorReadingModel({
    required this.readingId,
    required this.sensorId,
    required this.sensorType,
    required this.value,
    required this.timestamp,
    this.status = DeviceStatus.normal,
  });

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    print('🔄 Converting sensor reading JSON to model: $json');
    
    return SensorReadingModel(
      readingId: json['reading_id'] ?? 0,
      sensorId: json['sensor_id'] ?? 0,
      value: (json['value'] ?? 0).toDouble(),
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      sensorType: json['sensor_type'] ?? 'unknown',  // Replace null with 'unknown'
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case DeviceStatus.warning:
        statusStr = 'warning';
        break;
      case DeviceStatus.critical:
        statusStr = 'critical';
        break;
      default:
        statusStr = 'normal';
    }

    return {
      'reading_id': readingId,
      'sensor_id': sensorId,
      'sensor_type': sensorType,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'status': statusStr,
    };
  }

  String get displayValue {
    String unit = '';
    switch (sensorType) {
      case 'temperature':
        unit = '°C';
        break;
      case 'humidity':
        unit = '%';
        break;
      case 'gas':
        unit = 'ppm';
        break;
      default:
        unit = '';
    }
    return '${value.toStringAsFixed(1)} $unit';
  }

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
      default:
        return AppColors.success; // Fallback color
    }
  }

  IconData get sensorIcon {
    switch (sensorType) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'gas':
        return Icons.cloud;
      default:
        return Icons.sensors;
    }
  }
}