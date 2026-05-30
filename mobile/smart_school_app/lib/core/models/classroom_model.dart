import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'device_model.dart';
import 'sensor_model.dart';
import 'sensor_reading_model.dart';
import 'actuator_model.dart';
import 'camera_model.dart';

class ClassroomModel {
  final int classroomId;
  final int departmentId;
  final String name;
  final int capacity;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Non-database fields - calculated or fetched separately
  final List<DeviceModel> devices;
  final List<SensorModel> sensors;
  final List<ActuatorModel> actuators;
  final List<CameraModel> cameras;
  final List<SensorReadingModel> sensorReadings;
  final DeviceStatus status;

  ClassroomModel({
    required this.classroomId,
    required this.departmentId,
    required this.name,
    required this.capacity,
    required this.createdAt,
    required this.updatedAt,
    this.devices = const [],
    this.sensors = const [],
    this.actuators = const [],
    this.cameras = const [],
    this.sensorReadings = const [],
    this.status = DeviceStatus.normal,
  });
  @override
  String toString() {
    return 'ClassroomModel('
        'classroomId: $classroomId, '
        'departmentId: $departmentId, '
        'name: $name, '
        'capacity: $capacity, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'devices: $devices, '
        'sensors: $sensors, '
        'actuators: $actuators, '
        'cameras: $cameras, '
        'sensorReadings: $sensorReadings, '
        'status: $status'
        ')';
  }

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    print('🔄 Converting classroom JSON to model');
    print('🔑 JSON keys: ${json.keys.toList()}');
    
    // Parse devices if present
    List<DeviceModel> devicesList = [];
    if (json['devices'] != null) {
      print('📱 Devices found: ${json['devices'].length}');
      if (json['devices'] is List) {
        try {
          devicesList = (json['devices'] as List)
              .map((deviceJson) => DeviceModel.fromJson(deviceJson))
              .toList();
          print('✅ Devices parsed successfully: ${devicesList.length}');
        } catch (e) {
          print('❌ Error parsing devices: $e');
        }
      }
    } else {
      print('⚠️ No devices found in JSON');
    }

    // Parse sensors if present
    List<SensorModel> sensorsList = [];
    if (json['sensors'] != null) {
      print('📡 Sensors found: ${json['sensors'].length}');
      if (json['sensors'] is List) {
        try {
          sensorsList = (json['sensors'] as List)
              .map((sensorJson) {
                print('🔍 Parsing sensor: $sensorJson');
                return SensorModel.fromJson(sensorJson);
              })
              .toList();
          print('✅ Sensors parsed successfully: ${sensorsList.length}');
        } catch (e) {
          print('❌ Error parsing sensors: $e');
          print('❌ Stack trace: ${StackTrace.current}');
        }
      }
    } else {
      print('⚠️ No sensors found in JSON');
    }
    
    List<ActuatorModel> actuatorsList = [];
    if (json['actuators'] != null) {
      print('🎮 Actuators found: ${json['actuators'].length}');
      if (json['actuators'] is List) {
        try {
          actuatorsList = (json['actuators'] as List)
              .map((actuatorJson) => ActuatorModel.fromJson(actuatorJson))
              .toList();
          print('✅ Actuators parsed successfully: ${actuatorsList.length}');
        } catch (e) {
          print('❌ Error parsing actuators: $e');
        }
      }
    } else {
      print('⚠️ No actuators found in JSON');
    }
    
    List<CameraModel> camerasList = [];
    if (json['cameras'] != null) {
      print('📷 Cameras found: ${json['cameras'].length}');
      if (json['cameras'] is List) {
        try {
          camerasList = (json['cameras'] as List)
              .map((cameraJson) => CameraModel.fromJson(cameraJson))
              .toList();
          print('✅ Cameras parsed successfully: ${camerasList.length}');
        } catch (e) {
          print('❌ Error parsing cameras: $e');
        }
      }
    } else {
      print('⚠️ No cameras found in JSON');
    }
    
    // Parse sensor readings if present
    List<SensorReadingModel> sensorReadingsList = [];
    if (json['sensor_readings'] != null) {
      print('📊 Sensor readings found: ${json['sensor_readings'].length}');
      if (json['sensor_readings'] is List) {
        try {
          sensorReadingsList = (json['sensor_readings'] as List)
              .map((readingJson) {
                print('🔍 Parsing sensor reading: $readingJson');
                var reading = SensorReadingModel.fromJson(readingJson);
                print('✅ Parsed to: $reading');
                return reading;
              })
              .toList();
          print('✅ Sensor readings parsed successfully: ${sensorReadingsList.length}');
        } catch (e) {
          print('❌ Error parsing sensor readings: $e');
          print('❌ Stack trace: ${StackTrace.current}');
        }
      }
    } else {
      print('⚠️ No sensor readings found in JSON');
    }

    // Determine status from sensor readings or provided status
    DeviceStatus status = DeviceStatus.normal;
    if (json['status'] != null) {
      if (json['status'] is String) {
        switch (json['status']) {
          case 'warning':
            status = DeviceStatus.warning;
            break;
          case 'critical':
            status = DeviceStatus.critical;
            break;
          default:
            status = DeviceStatus.normal;
        }
      }
    } else {
      // Determine status from sensor readings if available
      for (var sensor in sensorReadingsList) {
        if (sensor.status == DeviceStatus.critical) {
          status = DeviceStatus.critical;
          break;
        } else if (sensor.status == DeviceStatus.warning) {
          status = DeviceStatus.warning;
        }
      }
    }

    return ClassroomModel(
      classroomId: json['classroom_id'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      name: json['name'] ?? 'Unknown Classroom',
      capacity: json['capacity'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      devices: devicesList,
      sensors: sensorsList,
      actuators: actuatorsList,
      cameras: camerasList,
      sensorReadings: sensorReadingsList,
      status: status,
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
      'classroom_id': classroomId,
      'department_id': departmentId,
      'name': name,
      'capacity': capacity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }

  // Get the latest reading of a specific sensor type
  SensorReadingModel? getLatestReading(String sensorType) {
    final filteredReadings = sensorReadings
        .where((reading) => reading.sensorType == sensorType)
        .toList();
    
    if (filteredReadings.isEmpty) {
      return null;
    }
    
    filteredReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filteredReadings.first;
  }

  // Get all devices of a specific type
  List<DeviceModel> getDevicesByType(String deviceType) {
    return devices.where((device) => device.deviceType == deviceType).toList();
  }

  // Check if classroom has a camera
  bool get hasCamera => cameras.isNotEmpty;

  // Get overall status color
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
}