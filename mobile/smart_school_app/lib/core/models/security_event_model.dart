import 'package:flutter/material.dart';

class SecurityEventModel {
  final int eventId;
  final String? deviceId;
  final String? eventType;
  final String? description;
  final String? location;
  final DateTime? timestamp;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final String? acknowledgedByUserId;
  final String? deviceName;  // Add this property
  
  SecurityEventModel({
    required this.eventId,
    this.deviceId,
    this.eventType,
    this.description,
    this.location,
    this.timestamp,
    required this.acknowledged,
    this.acknowledgedAt,
    this.acknowledgedByUserId,
    this.deviceName,  // Add this to the constructor
  });

  // Create a copy with updated fields
  SecurityEventModel copyWith({
    int? eventId,
    String? deviceId,
    String? eventType,
    String? description,
    String? location,
    DateTime? timestamp,
    bool? acknowledged,
    DateTime? acknowledgedAt,
    String? acknowledgedByUserId,
    String? deviceName,  // Add this to copyWith
  }) {
    return SecurityEventModel(
      eventId: eventId ?? this.eventId,
      deviceId: deviceId ?? this.deviceId,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedByUserId: acknowledgedByUserId ?? this.acknowledgedByUserId,
      deviceName: deviceName ?? this.deviceName,  // Add this to the constructor call
    );
  }

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    // Safely parse integer fields
    int parseIntSafely(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }
    
    // Safely handle boolean values
    bool parseBoolSafely(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      if (value is num) return value != 0;
      return false;
    }
    
    // Get device name from either direct field or nested device object
    String? deviceName = json['device_name'];
    if (deviceName == null && json['device'] != null) {
      deviceName = json['device']['name']?.toString();
    }
    
    return SecurityEventModel(
      eventId: parseIntSafely(json['event_id']),
      deviceId: json['device_id']?.toString(),
      eventType: json['event_type'],
      description: json['description'],
      location: json['location'],
      timestamp: json['timestamp'] != null 
          ? DateTime.tryParse(json['timestamp'].toString()) 
          : null,
      acknowledged: parseBoolSafely(json['acknowledged']),
      acknowledgedAt: json['acknowledged_at'] != null 
          ? DateTime.tryParse(json['acknowledged_at'].toString()) 
          : null,
      acknowledgedByUserId: json['acknowledged_by_user_id']?.toString(),
      deviceName: deviceName,  // Add this to the constructor call
    );
  }
}