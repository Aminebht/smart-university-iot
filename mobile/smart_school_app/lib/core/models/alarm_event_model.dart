import 'package:flutter/material.dart';

class AlarmEventModel {
  final int eventId;
  final int alarmId;
  final int? ruleId;
  final double? triggerValue;
  final String? triggerStatus;
  final int? triggeredByDeviceId;
  final String? deviceName;
  final String? deviceType;
  final String? ruleName;
  final DateTime triggeredAt;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final int? acknowledgedByUserId;
  final String? notes;

  AlarmEventModel({
    required this.eventId,
    required this.alarmId,
    this.ruleId,
    this.triggerValue,
    this.triggerStatus,
    this.triggeredByDeviceId,
    this.deviceName,
    this.deviceType,
    this.ruleName,
    required this.triggeredAt,
    required this.acknowledged,
    this.acknowledgedAt,
    this.acknowledgedByUserId,
    this.notes,
  });

  factory AlarmEventModel.fromJson(Map<String, dynamic> json) {
    return AlarmEventModel(
      eventId: json['event_id'],
      alarmId: json['alarm_id'],
      ruleId: json['rule_id'],
      triggerValue: json['trigger_value'] != null ? json['trigger_value'].toDouble() : null,
      triggerStatus: json['trigger_status'],
      triggeredByDeviceId: json['triggered_by_device_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      ruleName: json['rule_name'],
      triggeredAt: DateTime.parse(json['triggered_at']),
      acknowledged: json['acknowledged'] ?? false,
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at']) : null,
      acknowledgedByUserId: json['acknowledged_by_user_id'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'alarm_id': alarmId,
      'rule_id': ruleId,
      'trigger_value': triggerValue,
      'trigger_status': triggerStatus,
      'triggered_by_device_id': triggeredByDeviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'rule_name': ruleName,
      'triggered_at': triggeredAt.toIso8601String(),
      'acknowledged': acknowledged,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'acknowledged_by_user_id': acknowledgedByUserId,
      'notes': notes,
    };
  }

  String get formattedTime {
    final hours = triggeredAt.hour.toString().padLeft(2, '0');
    final minutes = triggeredAt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String get formattedDate {
    final month = triggeredAt.month.toString().padLeft(2, '0');
    final day = triggeredAt.day.toString().padLeft(2, '0');
    return '$month/$day/${triggeredAt.year}';
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(triggeredAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${triggeredAt.day}/${triggeredAt.month}/${triggeredAt.year}';
    }
  }

  IconData get icon {
    if (triggerStatus != null) {
      switch (triggerStatus!.toLowerCase()) {
        case 'breached':
          return Icons.security_update_warning;
        case 'secured':
          return Icons.shield;
        case 'offline':
          return Icons.power_off;
        default:
          return Icons.warning;
      }
    } else if (acknowledged) {
      return Icons.check_circle_outline;
    } else {
      return Icons.notifications_active;
    }
  }

  Color get color {
    if (triggerStatus != null) {
      switch (triggerStatus!.toLowerCase()) {
        case 'breached':
          return Colors.red;
        case 'secured':
          return Colors.green;
        case 'offline':
          return Colors.grey;
        default:
          return Colors.orange;
      }
    } else if (acknowledged) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  String get description {
    String desc = 'Alarm event';

    if (deviceName != null) {
      if (triggerStatus != null) {
        desc = '$deviceName is $triggerStatus';
      } else if (triggerValue != null) {
        desc = '$deviceName reported value: $triggerValue';
      } else {
        desc = '$deviceName triggered alarm';
      }
    } else if (ruleName != null) {
      desc = 'Rule "$ruleName" triggered';
    }

    return desc;
  }
}