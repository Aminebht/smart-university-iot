import '../constants/app_constants.dart';
import 'dart:convert';

class ActuatorModel {
  final int actuatorId;
  final int deviceId;
  final String actuatorType;
  final String? currentState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status;
  final String name;
  final Map<String, dynamic> settings;

  ActuatorModel({
    required this.actuatorId,
    required this.deviceId,
    required this.actuatorType,
    this.currentState,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.name,
    this.settings = const {},
  });

  // Factory constructor to create an ActuatorModel from JSON
  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
    // Parse settings from JSON, ensuring we have a valid map
    Map<String, dynamic> parsedSettings = {};
    if (json['settings'] != null) {
      try {
        if (json['settings'] is String) {
          // If settings is stored as a JSON string, parse it
          parsedSettings = Map<String, dynamic>.from(
              jsonDecode(json['settings']));
        } else if (json['settings'] is Map) {
          // If settings is already a map
          parsedSettings = Map<String, dynamic>.from(json['settings']);
        }
      } catch (e) {
        print('Error parsing actuator settings: $e');
      }
    }

    return ActuatorModel(
      actuatorId: json['actuator_id'],
      deviceId: json['device_id'],
      actuatorType: json['actuator_type'],
      currentState: json['current_state'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      status: _parseStatus(json['status']),
      name: json['name'] ?? 'Unnamed Actuator',
      settings: parsedSettings,
    );
  }

  // Helper method to parse device status from string
  static DeviceStatus _parseStatus(String? status) {
    if (status == null) return DeviceStatus.online;
    
    switch (status.toLowerCase()) {
      case 'online':
        return DeviceStatus.online;
      case 'maintenance':
        return DeviceStatus.maintenance;
      case 'offline':
      default:
        return DeviceStatus.offline;
    }
  }

  // Get brightness for light actuators (0-100)
  int get brightness {
    if (settings.containsKey('brightness')) {
      final value = settings['brightness'];
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? 100;
    }
    return 100; // Default value if not found
  }
  
  // Get speed for fan actuators (0-100)
  int get speed {
    if (settings.containsKey('speed')) {
      final value = settings['speed'];
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? 50;
    }
    return 50; // Default value if not found
  }
}