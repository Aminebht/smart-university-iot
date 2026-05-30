import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class DeviceModel {
  final int deviceId;
  final int? classroomId;
  final int? departmentId;
  final String name;
  final String deviceType;
  final String model;
  final String location;
  final String? ipAddress;
  final DeviceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceModel({
    required this.deviceId,
    this.classroomId,
    this.departmentId,
    required this.name,
    required this.deviceType,
    required this.model,
    required this.location,
    this.ipAddress,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      deviceId: json['device_id'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      classroomId: json['classroom_id'] ?? 0,
      name: json['name'] ?? 'unknown',
      deviceType: json['device_type'] ?? 'unknown',
      model: json['model'] ?? 'unknown',
      location: json['location'] ?? 'unknown',
      status: _parseStatus(json['status']),
      ipAddress: json['ip_address'], // This can be null
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  static DeviceStatus _parseStatus(String? status) {
    if (status == null) return DeviceStatus.offline;
    
    switch (status.toLowerCase()) {
      case 'online':
        return DeviceStatus.online;
      case 'offline':
        return DeviceStatus.offline;
      case 'maintenance':
        return DeviceStatus.maintenance;
      case 'warning':
        return DeviceStatus.warning;
      case 'critical':
        return DeviceStatus.critical;
      default:
        return DeviceStatus.offline;
    }
  }

  Map<String, dynamic> toJson() {
    String statusStr;
    switch (status) {
      case DeviceStatus.online:
        statusStr = 'online';
        break;
      case DeviceStatus.offline:
        statusStr = 'offline';
        break;
      case DeviceStatus.maintenance:
        statusStr = 'maintenance';
        break;
      case DeviceStatus.warning:
        statusStr = 'warning';
        break;
      case DeviceStatus.critical:
        statusStr = 'critical';
        break;
      case DeviceStatus.normal:
        statusStr = 'normal';
        break;
      default:
        statusStr = 'offline';
    }

    return {
      'device_id': deviceId,
      'department_id': departmentId,
      'classroom_id': classroomId,
      'name': name,
      'device_type': deviceType,
      'model': model,
      'location': location,
      'ip_address': ipAddress,
      'status': statusStr,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  IconData get deviceIcon {
    switch (deviceType) {
      case 'light':
        return status == DeviceStatus.online ? Icons.lightbulb : Icons.lightbulb_outline;
      case 'fan':
        return status == DeviceStatus.online ? Icons.air : Icons.air_outlined;
      case 'door':
        return status == DeviceStatus.online ? Icons.meeting_room : Icons.meeting_room_outlined;
      case 'window':
        return status == DeviceStatus.online ? Icons.window : Icons.window_outlined;
      case 'ac':
        return status == DeviceStatus.online ? Icons.ac_unit : Icons.ac_unit_outlined;
      default:
        return Icons.device_unknown;
    }
  }

  String get statusText {
    switch (deviceType) {
      case 'door':
      case 'window':
        return status == DeviceStatus.online ? 'Open' : 'Closed';
      default:
        return status == DeviceStatus.online ? 'On' : 'Off';
    }
  }

  bool get isToggleable {
    return deviceType == 'light' || deviceType == 'fan' || deviceType == 'ac';
  }

  bool get isAdjustable {
    return deviceType == 'fan' || deviceType == 'ac';
  }
  
  // Utility getter to replace the isOnline field that was removed
  bool get isOnline => status == DeviceStatus.online;
}