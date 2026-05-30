import 'package:flutter/material.dart';
import 'package:smart_school/features/dashboard/screens/dashboard_screen.dart';
import 'package:smart_school/features/presence/screens/student_presence_screen.dart';
import 'package:smart_school/features/settings/screens/settings_screen.dart';
import 'package:smart_school/features/alerts/screens/alerts_screen.dart';
import 'room_list_screen.dart';

class BottomNavContainer extends StatefulWidget {
  final int initialIndex;

  const BottomNavContainer({super.key, this.initialIndex = 0});

  @override
  State<BottomNavContainer> createState() => _BottomNavContainerState();
}

class _BottomNavContainerState extends State<BottomNavContainer> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    RoomListScreen(),
    StudentPresenceScreen(),
    AlertsScreen(),
    SettingsScreen(),
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
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.meeting_room),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Presence',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
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