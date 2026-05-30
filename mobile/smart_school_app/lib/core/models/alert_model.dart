// lib/core/models/alert_model.dart

import 'package:flutter/material.dart';

class AlertModel {
  final int alertId;
  final int deviceId;
  final String alertType;
  final String severity;
  final String message;
  final DateTime timestamp;
  final bool resolved;
  final DateTime? resolvedAt;
  final int? resolvedById;
  final String? deviceName;
  final String? deviceLocation;

  AlertModel({
    required this.alertId,
    required this.deviceId,
    required this.alertType,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.resolved,
    this.resolvedAt,
    this.resolvedById,
    this.deviceName,
    this.deviceLocation,
  });

  // Define these getters to fix the errors
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get alertIcon {
    switch (alertType.toLowerCase()) {
      case 'security':
        return Icons.security;
      case 'motion':
        return Icons.directions_run;
      case 'temperature':
        return Icons.thermostat;
      case 'smoke':
        return Icons.smoke_free;
      case 'water':
        return Icons.water_drop;
      case 'network':
        return Icons.wifi;
      case 'battery':
        return Icons.battery_alert;
      default:
        // Default icon based on severity
        switch (severity.toLowerCase()) {
          case 'critical':
            return Icons.error;
          case 'warning':
            return Icons.warning;
          default:
            return Icons.info;
        }
    }
  }
  
  // Add title getter for compatibility with RecentAlerts widget
  String get title {
    return alertType;
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
  return AlertModel(
    // Parse numeric fields with appropriate type conversion
    alertId: _parseIntField(json['alert_id']),
    deviceId: _parseIntField(json['device_id']),
    
    // String fields with null safety
    alertType: json['alert_type'] ?? 'Unknown',
    severity: json['severity'] ?? 'info',
    message: json['message'] ?? 'No details available',
    
    // Date fields with null safety
    timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp'].toString()) 
        : DateTime.now(),
    resolved: json['resolved'] == true,  // Handle any type safely
    resolvedAt: json['resolved_at'] != null 
        ? DateTime.parse(json['resolved_at'].toString()) 
        : null,
    
    // Nullable fields with type conversion
    resolvedById: json['resolved_by_user_id'] != null 
        ? _parseIntField(json['resolved_by_user_id']) 
        : null,
    
    // String fields from nested objects
    deviceName: json['device_name'] ?? 
                (json['devices'] != null ? json['devices']['model']?.toString() : null),
    deviceLocation: json['device_location'] ?? 
                   (json['devices'] != null ? json['devices']['location']?.toString() : null),
  );
}

// Add this helper method in your AlertModel class
static int _parseIntField(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0; // Default value if parsing fails
}
}