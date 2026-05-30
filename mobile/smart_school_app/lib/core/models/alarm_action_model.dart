import 'package:flutter/material.dart';

class AlarmActionModel {
  final int actionId;
  final int alarmId;
  final int ruleId;
  final String actionType; // 'notify', 'actuate',
  final int? actuatorId;
  final String? targetState;
  final String? notificationSeverity; // 'info', 'warning', 'critical'
  final String? notificationMessage;
  final List<int>? notifyUserIds;
  final String? externalWebhookUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AlarmActionModel({
    required this.actionId,
    required this.alarmId,
    required this.ruleId,
    required this.actionType,
    this.actuatorId,
    this.targetState,
    this.notificationSeverity,
    this.notificationMessage,
    this.notifyUserIds,
    this.externalWebhookUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AlarmActionModel.fromJson(Map<String, dynamic> json) {
    return AlarmActionModel(
      actionId: json['action_id'],
      alarmId: json['alarm_id'],
      ruleId: json['rule_id'],
      actionType: json['action_type'],
      actuatorId: json['actuator_id'],
      targetState: json['target_state'],
      notificationSeverity: json['notification_severity'],
      notificationMessage: json['notification_message'],
      notifyUserIds: json['notify_user_ids'] != null 
          ? List<int>.from(json['notify_user_ids'])
          : null,
      externalWebhookUrl: json['external_webhook_url'],
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
  final map = {
    'action_id': actionId != 0 ? actionId : null, // Use null for new records
    'alarm_id': alarmId,
    'rule_id': ruleId,
    'action_type': actionType,
    'actuator_id': actuatorId,
    'target_state': targetState,
    'notification_severity': notificationSeverity,
    'notification_message': notificationMessage,
    'notify_user_ids': notifyUserIds,
    'external_webhook_url': externalWebhookUrl,
    'is_active': isActive,
    // Don't include created_at and updated_at for new records
  };
  
  // Remove null values
  map.removeWhere((key, value) => value == null);
  return map;
}
  
  IconData get actionIcon {
    switch (actionType) {
      case 'notify':
        return Icons.notifications;
      case 'actuate':
        return Icons.touch_app;
      default:
        return Icons.settings;
    }
  }
  
  Color get severityColor {
    switch (notificationSeverity?.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String get actionDescription {
    switch (actionType) {
      case 'notify':
        return 'Send ${notificationSeverity ?? ''} notification';
      case 'actuate':
        return 'Set actuator to ${targetState ?? 'on'}';
      default:
        return actionType;
    }
  }

  IconData get icon {
    switch (actionType) {
      case 'notify':
        return Icons.notifications;
      case 'actuate':
        return Icons.touch_app;
      default:
        return Icons.flash_on;
    }
  }

  Color get color {
    if (actionType == 'notify' && notificationSeverity != null) {
      switch (notificationSeverity) {
        case 'critical':
          return Colors.red;
        case 'warning':
          return Colors.orange;
        case 'info':
        default:
          return Colors.blue;
      }
    } else if (actionType == 'actuate') {
      return Colors.green;
    }
     else {
      return Colors.grey;
    }
  }
}