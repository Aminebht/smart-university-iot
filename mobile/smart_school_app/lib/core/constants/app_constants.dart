import 'package:flutter/material.dart';

// App name and version
const String appName = 'Smart School';
const String appVersion = '0.1.0';

// Supabase configuration — new Smart University project
const String supabaseUrl = 'https://xfkoghbyrnijtkvrvjsc.supabase.co';
const String supabaseAnonKey = 'sb_publishable_yebX_K19ej805y4-VIpswg_XBF8n5E6';

// Stream server base URL (room-specific ws path appended per-room)
const String streamServerBaseUrl = 'ws://192.168.1.100:3000';

// Theme colors
class AppColors {
  static const Color primary = Color(0xFF002255);
  static const Color secondary = Color(0xFFFBE822);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFA71D31);
  static const Color warning = Color(0xFFF44708);
  static const Color success = Color(0xFF426A5A);
  static const Color text = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color info = Color(0xFF2196F3); // Added 'info' color
}

// Status indicators
enum DeviceStatus {
  normal,
  warning,
  critical,
  online,
  offline,
  maintenance
}

// Routes
class AppRoutes {
  // Auth routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String resetPassword = '/reset-password';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String room = '/room';
  static const String camera = '/camera';
  static const String presence = '/presence';
  static const String alerts = '/alerts';
  static const String settings = '/settings';

  // Legacy routes (hidden from nav but preserved)
  static const String department = '/department';
  static const String classroom = '/classroom'; // deprecated, use /room
  static const String security = '/security';
  static const String securityEvents = '/security/events';
  static const String alarmSystems = '/alarm-systems';
  static const String alarmDetail = '/alarm-detail';
  static const String alarmEdit = '/alarm-edit';
  static const String alarmEvents = '/alarm-events';
  static const String alarmRules = '/alarm-rules';
  static const String studentPresence = '/student-presence'; // deprecated, use /presence
}