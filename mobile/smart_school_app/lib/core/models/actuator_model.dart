import 'dart:convert';
import '../constants/app_constants.dart';

class ActuatorModel {
  final int id;
  final String roomId;
  final String actuatorId;
  final String actuatorType;
  final String currentState;
  final String? command;
  final String targetDevice;
  final Map<String, dynamic> settings;
  final DateTime updatedAt;

  ActuatorModel({
    required this.id,
    required this.roomId,
    required this.actuatorId,
    required this.actuatorType,
    this.currentState = 'off',
    this.command,
    this.targetDevice = 'esp32',
    this.settings = const {},
    required this.updatedAt,
  });

  factory ActuatorModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedSettings = {};
    if (json['settings'] != null) {
      try {
        if (json['settings'] is String) {
          parsedSettings = Map<String, dynamic>.from(jsonDecode(json['settings']));
        } else if (json['settings'] is Map) {
          parsedSettings = Map<String, dynamic>.from(json['settings']);
        }
      } catch (e) {
        // silently ignore parse errors
      }
    }

    return ActuatorModel(
      id: json['id'] ?? 0,
      roomId: json['room_id'] ?? '',
      actuatorId: json['actuator_id'] ?? '',
      actuatorType: json['actuator_type'] ?? 'unknown',
      currentState: json['current_state'] ?? 'off',
      command: json['command'],
      targetDevice: json['target_device'] ?? 'esp32',
      settings: parsedSettings,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'actuator_id': actuatorId,
      'actuator_type': actuatorType,
      'current_state': currentState,
      'command': command,
      'target_device': targetDevice,
      'settings': settings,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOn => currentState.toLowerCase() == 'on';

  String get name => displayName;
  String get deviceId => actuatorId;
  DeviceStatus get status => DeviceStatus.normal;
  DateTime get createdAt => updatedAt;
  int get brightness => (settings['brightness'] as int?) ?? 50;
  int get speed => (settings['speed'] as int?) ?? 50;

  String get displayName {
    switch (actuatorType.toLowerCase()) {
      case 'servo': return 'Door Lock';
      case 'buzzer': return 'Buzzer';
      case 'led_rgb': return 'LED RGB';
      case 'relay': return 'Fan / Ventilation';
      case 'lcd': return 'LCD Display';
      default: return actuatorType;
    }
  }
}