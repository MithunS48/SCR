import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/tracker/screens/tracker_screen.dart';
import '../../features/reports/screens/report_waste_screen.dart';
import '../../features/map/screens/heatmap_screen.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/awareness/screens/awareness_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/gamification/screens/leaderboard_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_awareness_screen.dart';
import '../../features/chat/screens/chat_screen.dart';

/// Centralized route definitions.
class AppRouter {
  // Auth
  static const String login    = '/login';
  static const String register = '/register';

  // User routes
  static const String dashboard   = '/dashboard';
  static const String tracker     = '/tracker';
  static const String reportWaste = '/report-waste';
  static const String heatmap     = '/heatmap';
  static const String events      = '/events';
  static const String eventDetail = '/event-detail';
  static const String awareness   = '/awareness';
  static const String profile     = '/profile';
  static const String leaderboard = '/leaderboard';
  static const String chat        = '/chat';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminReports   = '/admin/reports';
  static const String adminAwareness = '/admin/awareness';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth
      case login:    return _route(const LoginScreen());
      case register: return _route(const RegisterScreen());

      // User
      case dashboard:   return _route(const DashboardScreen());
      case tracker:     return _route(const TrackerScreen());
      case reportWaste: return _route(const ReportWasteScreen());
      case heatmap:     return _route(const HeatmapScreen());
      case events:      return _route(const EventsScreen());
      case eventDetail:
        final eventId = settings.arguments as int;
        return _route(EventDetailScreen(eventId: eventId));
      case awareness:   return _route(const AwarenessScreen());
      case profile:     return _route(const ProfileScreen());
      case leaderboard: return _route(const LeaderboardScreen());
      case chat:        return _route(const ChatScreen());

      // Admin
      case adminDashboard: return _route(const AdminDashboardScreen());
      case adminReports:   return _route(const AdminReportsScreen());
      case adminAwareness: return _route(const AdminAwarenessScreen());

      default: return _route(const LoginScreen());
    }
  }

  static MaterialPageRoute _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
