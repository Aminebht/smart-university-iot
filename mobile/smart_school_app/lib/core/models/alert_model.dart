import 'package:flutter/material.dart';

class AlertModel {
  final int id;
  final String roomId;
  final String alertType;
  final String severity;
  final String? message;
  final int? personCount;
  final DateTime timestamp;
  final bool acknowledged;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.roomId,
    required this.alertType,
    required this.severity,
    this.message,
    this.personCount,
    required this.timestamp,
    required this.acknowledged,
    required this.createdAt,
  });

  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.deepOrange;
      case 'warning': return Colors.orange;
      case 'medium': return Colors.amber;
      case 'low': return Colors.blue;
      case 'info': return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  IconData get alertIcon {
    switch (alertType.toLowerCase()) {
      case 'intrusion': return Icons.warning_amber;
      case 'threshold_gas': return Icons.cloud;
      case 'threshold_temperature': return Icons.thermostat;
      case 'threshold_humidity': return Icons.water_drop;
      case 'threshold_distance': return Icons.social_distance;
      case 'device_offline': return Icons.wifi_off;
      default: return Icons.notifications;
    }
  }

  String get title {
    if (alertType.startsWith('threshold_')) {
      return 'Threshold: ${alertType.replaceFirst('threshold_', '')}';
    }
    return alertType;
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      roomId: json['room_id'] ?? '',
      alertType: json['alert_type'] ?? 'unknown',
      severity: json['severity'] ?? 'medium',
      message: json['message']?.toString(),
      personCount: json['person_count'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      acknowledged: json['acknowledged'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'alert_type': alertType,
      'severity': severity,
      'message': message,
      'person_count': personCount,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
      'created_at': createdAt.toIso8601String(),
    };
  }
}