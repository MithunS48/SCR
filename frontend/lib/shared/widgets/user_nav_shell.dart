import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/tracker/screens/tracker_screen.dart';
import '../../features/reports/screens/report_waste_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/awareness/screens/awareness_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

/// Persistent bottom navigation shell for regular users.
class UserNavShell extends StatefulWidget {
  final int initialIndex;
  const UserNavShell({super.key, this.initialIndex = 0});

  @override
  State<UserNavShell> createState() => _UserNavShellState();
}

class _UserNavShellState extends State<UserNavShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TrackerScreen(),
    ReportWasteScreen(),
    EventsScreen(),
    ChatScreen(),
    AwarenessScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 30),
            activeIcon: Icon(Icons.add_circle, size: 30),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
