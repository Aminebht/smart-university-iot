import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/models/camera_model.dart';
import 'package:smart_school/features/alerts/providers/alerts_provider.dart';
import 'package:smart_school/features/alerts/screens/alerts_screen.dart';
import 'package:smart_school/features/presence/providers/attendance_provider.dart';
import 'package:smart_school/features/presence/screens/student_presence_screen.dart';
import 'core/constants/app_constants.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/camera/screens/camera_view_screen.dart';
import 'features/navigation/screens/room_detail_screen.dart';
// Legacy screens (hidden from nav but preserved)
import 'features/security/screens/security_dashboard_screen.dart';
import 'features/security/screens/security_events_screen.dart';
import 'features/security/providers/security_provider.dart';
import 'features/security/screens/alarm_systems_screen.dart';
import 'features/security/screens/alarm_edit_screen.dart';
import 'features/security/screens/alarm_events_screen.dart';
import 'features/security/screens/alarm_rules_screen.dart';
import 'features/security/screens/alarm_detail_screen.dart';
import 'services/supabase_service.dart';
import 'features/navigation/screens/bottom_nav_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Create and initialize auth provider first
  final authProvider = AuthProvider();
  await authProvider.initializeAuth();
  
  runApp(SmartSchoolApp(authProvider: authProvider));
}

class SmartSchoolApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const SmartSchoolApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()), // Make sure this is here
        ChangeNotifierProvider(create: (_) => AttendanceProvider()), // Add AttendanceProvider here
        // Other providers...
      ],
      child: MaterialApp(
        title: 'Smart School',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            error: AppColors.error,
            background: AppColors.background,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.resetPassword: (context) => const ResetPasswordScreen(),
          AppRoutes.signup: (context) => const SignUpScreen(),

          // Main bottom-nav tabs: Dashboard | Rooms | Presence | Alerts | Settings
          AppRoutes.dashboard: (context) => const BottomNavContainer(initialIndex: 0),
          AppRoutes.room: (context) => const BottomNavContainer(initialIndex: 1),
          AppRoutes.presence: (context) => const BottomNavContainer(initialIndex: 2),
          AppRoutes.alerts: (context) => const BottomNavContainer(initialIndex: 3),
          AppRoutes.settings: (context) => const BottomNavContainer(initialIndex: 4),

          // Legacy routes (hidden from nav but preserved)
          AppRoutes.securityEvents: (context) => const SecurityEventsScreen(),
          AppRoutes.alarmSystems: (context) => const AlarmSystemsScreen(),
          AppRoutes.studentPresence: (context) => const StudentPresenceScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.room && settings.arguments != null) {
            // Room detail expects roomId string
            return MaterialPageRoute(
              builder: (context) => RoomDetailScreen(
                roomId: settings.arguments as String,
              ),
            );
          }
          if (settings.name == AppRoutes.camera && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => CameraViewScreen(
                camera: settings.arguments as CameraModel,
              ),
            );
          }
          // Legacy alarm routes (preserved but hidden)
          if (settings.name == AppRoutes.alarmDetail && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => AlarmDetailScreen(alarmId: settings.arguments as int),
            );
          }
          if (settings.name == AppRoutes.alarmEdit) {
            final alarmId = settings.arguments as int?;
            return MaterialPageRoute(
              builder: (context) => AlarmEditScreen(alarmId: alarmId),
            );
          }
          if (settings.name == AppRoutes.alarmEvents && settings.arguments != null) {
            return MaterialPageRoute(
              builder: (context) => AlarmEventsScreen(alarmId: settings.arguments as int),
            );
          }
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Page Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('The requested page was not found.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context, 
                        AppRoutes.dashboard
                      ),
                      child: const Text('Go to Dashboard'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
