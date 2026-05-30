import 'package:flutter/material.dart';

class AlarmRuleModel {
  final int ruleId;
  final int alarmId;
  final String ruleName;
  final int deviceId;
  final String conditionType; // 'threshold', 'status_change', 'motion_detected', 'schedule'
  final double? thresholdValue;
  final String? comparisonOperator; // '>', '<', '>=', '<=', '=', '<>'
  final String? statusValue;
  final DateTime? timeRestrictionStart; // Store full DateTime
  final DateTime? timeRestrictionEnd; // Store full DateTime
  final String? daysActive; // e.g., 'mon,tue,wed,thu,fri'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AlarmRuleModel({
    required this.ruleId,
    required this.alarmId,
    required this.ruleName,
    required this.deviceId,
    required this.conditionType,
    this.thresholdValue,
    this.comparisonOperator,
    this.statusValue,
    this.timeRestrictionStart,
    this.timeRestrictionEnd,
    this.daysActive,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Add methods to get TimeOfDay for UI
  TimeOfDay? get startTimeOfDay => timeRestrictionStart != null 
      ? TimeOfDay(hour: timeRestrictionStart!.hour, minute: timeRestrictionStart!.minute)
      : null;
      
  TimeOfDay? get endTimeOfDay => timeRestrictionEnd != null 
      ? TimeOfDay(hour: timeRestrictionEnd!.hour, minute: timeRestrictionEnd!.minute)
      : null;
  
  // Fix the getter for conditionText
  String get conditionText {
    switch (conditionType) {
      case 'threshold':
        return 'Value $comparisonOperator $thresholdValue';
      case 'status_change':
        return 'Status changes to $statusValue';
      case 'motion_detected':
        return 'Motion is detected';
      case 'schedule':
        final startTime = timeRestrictionStart != null 
            ? '${timeRestrictionStart!.hour.toString().padLeft(2, '0')}:${timeRestrictionStart!.minute.toString().padLeft(2, '0')}'
            : 'any time';
        final endTime = timeRestrictionEnd != null 
            ? '${timeRestrictionEnd!.hour.toString().padLeft(2, '0')}:${timeRestrictionEnd!.minute.toString().padLeft(2, '0')}'
            : 'any time';
        return 'Active from $startTime to $endTime on ${daysActive ?? 'all days'}';
      default:
        return 'Unknown condition';
    }
  }
  
  // Add the icon getter that was referenced in the UI
  IconData get icon {
    switch (conditionType) {
      case 'threshold':
        return Icons.trending_up;
      case 'status_change':
        return Icons.compare_arrows;
      case 'motion_detected':
        return Icons.motion_photos_on;
      case 'schedule':
        return Icons.schedule;
      default:
        return Icons.rule;
    }
  }
  
  // Factory for creating from JSON
  factory AlarmRuleModel.fromJson(Map<String, dynamic> json) {
    return AlarmRuleModel(
      ruleId: json['rule_id'],
      alarmId: json['alarm_id'],
      ruleName: json['rule_name'],
      deviceId: json['device_id'],
      conditionType: json['condition_type'],
      thresholdValue: json['threshold_value'] != null ? double.parse(json['threshold_value'].toString()) : null,
      comparisonOperator: json['comparison_operator'],
      statusValue: json['status_value'],
      timeRestrictionStart: json['time_restriction_start'] != null 
          ? DateTime.parse(json['time_restriction_start']) 
          : null,
      timeRestrictionEnd: json['time_restriction_end'] != null 
          ? DateTime.parse(json['time_restriction_end']) 
          : null,
      daysActive: json['days_active'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'rule_id': ruleId == 0 ? null : ruleId, // Send null for new rules
      'alarm_id': alarmId,
      'rule_name': ruleName,
      'device_id': deviceId,
      'condition_type': conditionType,
      'threshold_value': thresholdValue,
      'comparison_operator': comparisonOperator,
      'status_value': statusValue,
      'time_restriction_start': timeRestrictionStart?.toIso8601String(),
      'time_restriction_end': timeRestrictionEnd?.toIso8601String(),
      'days_active': daysActive,
      'is_active': isActive,
    };
  }
}