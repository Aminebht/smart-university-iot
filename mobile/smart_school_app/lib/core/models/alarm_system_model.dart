import 'package:flutter/material.dart';

class AlarmSystemModel {
  final int alarmId;
  final String name;
  final String description;
  final int? departmentId;
  final int? classroomId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AlarmSystemModel({
    required this.alarmId,
    required this.name,
    required this.description,
    this.departmentId,
    this.classroomId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AlarmSystemModel.fromJson(Map<String, dynamic> json) {
    return AlarmSystemModel(
      alarmId: json['alarm_id'],
      name: json['name'],
      description: json['description'] ?? '',
      departmentId: json['department_id'],
      classroomId: json['classroom_id'],
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'alarm_id': alarmId != 0 ? alarmId : null, // Use null for new alarms
      'name': name,
      'description': description,
      'department_id': departmentId,
      'classroom_id': classroomId,
      'is_active': isActive,
    };
  }
  
  // Constructor for copying with modifications
  AlarmSystemModel copyWith({
    int? alarmId,
    String? name,
    String? description,
    int? departmentId,
    int? classroomId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlarmSystemModel(
      alarmId: alarmId ?? this.alarmId,
      name: name ?? this.name,
      description: description ?? this.description,
      departmentId: departmentId ?? this.departmentId,
      classroomId: classroomId ?? this.classroomId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Get status color based on active status
  Color get statusColor {
    return isActive ? Colors.green : Colors.red;
  }
  
  // Get status text for display
  String get statusText {
    return isActive ? 'Active' : 'Inactive';
  }
  
  // Get icon for the alarm system
  IconData get icon {
    return isActive ? Icons.security : Icons.security_outlined;
  }

  // Get status icon for the alarm system
  IconData get statusIcon {
    return isActive ? Icons.security : Icons.security_outlined;
  }

  // Get display status for the alarm system
  String get displayStatus {
    return isActive ? 'Active' : 'Inactive';
  }

  // Get department name
  String? get departmentName {
    if (departmentId == null) return null;
    // This should properly return the department name from somewhere
    // For now, let's return a placeholder
    return 'Department $departmentId';
  }

  // Get classroom name
  String? get classroomName {
    if (classroomId == null) return null;
    // This should properly return the classroom name from somewhere
    // For now, let's return a placeholder
    return 'Classroom $classroomId';
  }
}