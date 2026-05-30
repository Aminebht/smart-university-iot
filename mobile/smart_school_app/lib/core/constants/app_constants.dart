import 'package:flutter/material.dart';

// App name and version
const String appName = 'Smart School';
const String appVersion = '0.1.0';

// Supabase configuration
const String supabaseUrl = 'https://wkvkynmbnqycxnkfdvip.supabase.co'; // Replace with your Supabase URL
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indrdmt5bm1ibnF5Y3hua2ZkdmlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDMyMzE4OTUsImV4cCI6MjA1ODgwNzg5NX0.kj95zrdFOJaBRZoJ4SBRcv2TDfC5rQeNliaCubsM6Sk'; // Replace with your Supabase anon key

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
  // Existing routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String department = '/department';
  static const String classroom = '/classroom';
  static const String camera = '/camera';
  static const String security = '/security';
  static const String securityEvents = '/security/events';
  static const String alarmSystems = '/alarm-systems';
  static const String alarmDetail = '/alarm-detail';
  static const String alarmEdit = '/alarm-edit';
  static const String alarmEvents = '/alarm-events';
  static const String alarmRules = '/alarm-rules';
  static const String alerts = '/alerts';
  // New routes
  static const String studentPresence = '/student-presence';
  static const String settings = '/settings';
}