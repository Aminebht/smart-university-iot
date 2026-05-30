import '../constants/app_constants.dart';

class DepartmentModel {
  final int departmentId;
  final String name;
  final int floorNumber;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceStatus status; // Calculated status based on devices/alerts

  DepartmentModel({
    required this.departmentId,
    required this.name,
    required this.floorNumber,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.status = DeviceStatus.normal,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    DeviceStatus status = DeviceStatus.normal;
    if (json['status'] != null) {
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

    return DepartmentModel(
      departmentId: json['department_id'],
      name: json['name'],
      floorNumber: json['floor_number'] ?? 1,
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'department_id': departmentId,
      'name': name,
      'floor_number': floorNumber,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': statusStr,
    };
  }
} 