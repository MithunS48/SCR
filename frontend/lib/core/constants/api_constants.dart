import 'package:flutter/foundation.dart' show kIsWeb;

/// API base URL and endpoint constants.
class ApiConstants {
  static String get baseUrl {
    const prodUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (prodUrl.isNotEmpty) return prodUrl;
    if (kIsWeb) return 'http://localhost:8080/api';
    return 'http://10.0.2.2:8080/api';
  }

  // Auth
  static const String register = '/auth/register';
  static const String login    = '/auth/login';
  static const String refresh  = '/auth/refresh';

  // Usage
  static const String usage          = '/usage';
  static const String usageHistory   = '/usage/history';
  static const String usageDaily     = '/usage/stats/daily';
  static const String usageWeekly    = '/usage/stats/weekly';
  static const String usageMonthly   = '/usage/stats/monthly';
  static const String usageReduction = '/usage/stats/reduction';

  // Reports
  static const String reports   = '/reports';
  static const String myReports = '/reports/mine';
  static const String heatmap   = '/reports/heatmap';

  // Events
  static const String events = '/events';

  // Awareness
  static const String awareness = '/awareness';

  // Users
  static const String profile     = '/users/me';
  static const String leaderboard = '/users/leaderboard';

  // Chat
  static const String chat       = '/chat';
  static const String chatLatest = '/chat/latest';
}
