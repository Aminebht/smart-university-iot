import '../constants/app_constants.dart';

class SensorModel {
  final int sensorId;
  final int deviceId;
  final int? classroomId;
  final String name;
  final String type;
  final String unit;
  final double minValue;
  final double maxValue;
  final double warningThreshold;
  final double criticalThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status;
  final String? sensorType;

  SensorModel({
    required this.sensorId,
    required this.deviceId,
    this.classroomId,
    required this.name,
    required this.type,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.warningThreshold, 
    required this.criticalThreshold,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
    this.sensorType,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      sensorId: json['sensor_id'] ?? 0,
      deviceId: json['device_id'] ?? 0,
      classroomId: json['classroom_id'],
      name: json['name'] ?? json['device_model'] ?? 'Unknown Sensor',
      type: json['sensor_type'] ?? 'unknown',
      unit: json['measurement_unit'] ?? '',
      minValue: (json['min_threshold'] ?? 0).toDouble(),
      maxValue: (json['max_threshold'] ?? 0).toDouble(),
      warningThreshold: json['warning_threshold']?.toDouble() ?? 70.0,
      criticalThreshold: json['critical_threshold']?.toDouble() ?? 90.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      sensorType: json['sensor_type'] ?? 'unknown',
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
      'sensor_id': sensorId,
      'device_id': deviceId,
      'classroom_id': classroomId,
      'name': name,
      'type': type,
      'unit': unit,
      'min_value': minValue,
      'max_value': maxValue,
      'warning_threshold': warningThreshold,
      'critical_threshold': criticalThreshold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }
}