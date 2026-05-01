import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../dashboard/widgets/stats_charts.dart';
import '../../events/screens/create_event_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiClient _api = ApiClient();

  Map<String, int> _reportCounts = {};
  int _totalUsers    = 0;
  int _totalEvents   = 0;
  int _totalMessages = 0;
  bool _loading      = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      // Load reports with each status
      final statuses = ['PENDING', 'APPROVED', 'REJECTED', 'CLEANED'];
      final counts = <String, int>{};
      for (final s in statuses) {
        try {
          final res = await _api.dio.get(ApiConstants.reports,
              queryParameters: {'status': s, 'page': 0, 'size': 1});
          counts[s] = res.data['data']['totalElements'] ?? 0;
        } catch (_) {
          counts[s] = 0;
        }
      }

      // Load events count
      try {
        final evRes = await _api.dio.get(ApiConstants.events,
            queryParameters: {'page': 0, 'size': 1});
        _totalEvents = evRes.data['data']['totalElements'] ?? 0;
      } catch (_) {}

      // Load chat messages count
      try {
        final chatRes = await _api.dio.get(ApiConstants.chat,
            queryParameters: {'page': 0, 'size': 1});
        _totalMessages = chatRes.data['data']['totalElements'] ?? 0;
      } catch (_) {}

      setState(() => _reportCounts = counts);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final totalReports = _reportCounts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Welcome, ${auth.user?.displayName ?? 'Admin'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const Text('Administrator',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Overview stats row ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                          label: 'Total Reports',
                          value: '$totalReports',
                          icon: Icons.report_problem_outlined,
                          color: Colors.orange),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          label: 'Pending',
                          value: '${_reportCounts['PENDING'] ?? 0}',
                          icon: Icons.pending_actions,
                          color: AppTheme.warning),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          label: 'Events',
                          value: '$_totalEvents',
                          icon: Icons.event,
                          color: Colors.blue),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                          label: 'Chat Msgs',
                          value: '$_totalMessages',
                          icon: Icons.chat_bubble_outline,
                          color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Reports status chart ───────────────────────────────
                if (_reportCounts.isNotEmpty)
                  ReportStatusChart(statusCounts: _reportCounts),
                const SizedBox(height: 16),

                // ── Report approval rate ───────────────────────────────
                if (totalReports > 0) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Approval Rate',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _ApprovalBar(
                                  label: 'Approved',
                                  count: _reportCounts['APPROVED'] ?? 0,
                                  total: totalReports,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ApprovalBar(
                                  label: 'Cleaned',
                                  count: _reportCounts['CLEANED'] ?? 0,
                                  total: totalReports,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Management grid ────────────────────────────────────
                const Text('Management',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: [
                    _AdminCard(
                      icon: Icons.report_problem_outlined,
                      title: 'Reports',
                      subtitle: '${_reportCounts['PENDING'] ?? 0} pending',
                      color: Colors.orange,
                      badge: (_reportCounts['PENDING'] ?? 0) > 0
                          ? '${_reportCounts['PENDING']}'
                          : null,
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.adminReports),
                    ),
                    _AdminCard(
                      icon: Icons.event_outlined,
                      title: 'Events',
                      subtitle: '$_totalEvents total',
                      color: Colors.blue,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.events),
                    ),
                    _AdminCard(
                      icon: Icons.add_circle_outline,
                      title: 'Create Event',
                      subtitle: 'Add new event',
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateEventScreen()),
                      ),
                    ),
                    _AdminCard(
                      icon: Icons.eco_outlined,
                      title: 'Awareness',
                      subtitle: 'Manage content',
                      color: AppTheme.primary,
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.adminAwareness),
                    ),
                    _AdminCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat',
                      subtitle: '$_totalMessages messages',
                      color: Colors.teal,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.chat),
                    ),
                    _AdminCard(
                      icon: Icons.map_outlined,
                      title: 'Heatmap',
                      subtitle: 'Pollution map',
                      color: Colors.red,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.heatmap),
                    ),
                    _AdminCard(
                      icon: Icons.leaderboard_outlined,
                      title: 'Leaderboard',
                      subtitle: 'Top users',
                      color: Colors.amber[700]!,
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.leaderboard),
                    ),
                    _AdminCard(
                      icon: Icons.swap_horiz,
                      title: 'User View',
                      subtitle: 'Switch to user',
                      color: AppTheme.textSecondary,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRouter.dashboard),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 10)),
            ],
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ApprovalBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _ApprovalBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text('${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
        Text('$count reports',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }
}
