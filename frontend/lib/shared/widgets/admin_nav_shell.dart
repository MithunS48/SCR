import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/admin/screens/admin_awareness_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/map/screens/heatmap_screen.dart';
import '../../features/gamification/screens/leaderboard_screen.dart';

/// Persistent bottom navigation shell for admin users.
class AdminNavShell extends StatefulWidget {
  final int initialIndex;
  const AdminNavShell({super.key, this.initialIndex = 0});

  @override
  State<AdminNavShell> createState() => _AdminNavShellState();
}

class _AdminNavShellState extends State<AdminNavShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminReportsScreen(),
    EventsScreen(),
    AdminAwarenessScreen(),
    ChatScreen(),
    HeatmapScreen(),
    LeaderboardScreen(),
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
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem_outlined),
            activeIcon: Icon(Icons.report_problem),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: 'Awareness',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Heatmap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined),
            activeIcon: Icon(Icons.leaderboard),
            label: 'Ranks',
          ),
        ],
      ),
    );
  }
}
