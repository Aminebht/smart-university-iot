import 'package:flutter/material.dart';
import 'package:smart_school/features/dashboard/screens/dashboard_screen.dart';
import 'package:smart_school/features/department/screens/department_list_screen.dart';
import 'package:smart_school/features/security/screens/security_dashboard_screen.dart';
import 'package:smart_school/features/presence/screens/student_presence_screen.dart';
import 'package:smart_school/features/settings/screens/settings_screen.dart'; // Make sure this exists

class BottomNavContainer extends StatefulWidget {
  final int initialIndex;

  const BottomNavContainer({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<BottomNavContainer> createState() => _BottomNavContainerState();
}

class _BottomNavContainerState extends State<BottomNavContainer> {
  late int _currentIndex;
  
  // Update this list to include both StudentPresenceScreen and SettingsScreen
  final List<Widget> _screens = [
    const DashboardScreen(),
    const DepartmentListScreen(),
    const SecurityDashboardScreen(),
    const StudentPresenceScreen(),
    const SettingsScreen(), // Assuming you have a settings screen
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed, // Important for displaying more than 3 items
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Departments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Security',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Presence',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}