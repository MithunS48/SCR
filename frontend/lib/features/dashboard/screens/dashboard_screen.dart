import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/gamification_provider.dart';
import '../../../core/providers/report_provider.dart';
import '../../../core/providers/event_provider.dart';
import '../../../core/providers/usage_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../widgets/stats_charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      context.read<GamificationProvider>().loadProfile();
      context.read<ReportProvider>().loadMyReports();
      context.read<EventProvider>().loadEvents();
      final usageProv = context.read<UsageProvider>();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      usageProv.loadDailyStats(dateStr);
      usageProv.loadWeeklyStats(now.year, _isoWeek(now));
      usageProv.loadMonthlyStats(now.year, now.month);
      usageProv.loadReduction('week',
          '${now.year}-W${_isoWeek(now).toString().padLeft(2, '0')}');
    });
  }

  int _isoWeek(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final gamif   = context.watch<GamificationProvider>();
    final reports = context.watch<ReportProvider>();
    final events  = context.watch<EventProvider>();
    final usage   = context.watch<UsageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlasticWatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
                // Greeting
                Text('Hello, ${auth.user?.displayName ?? 'User'} 👋',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Text("Let's make a difference today!",
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 16),

                // ── Stats row ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Points',
                        value: '${gamif.totalPoints}',
                        icon: Icons.stars,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        label: 'Rank',
                        value: '#${gamif.rank}',
                        icon: Icons.leaderboard,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        label: 'Badges',
                        value: '${gamif.badges.length}',
                        icon: Icons.emoji_events,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatTile(
                        label: 'Reports',
                        value: '${reports.myReports.length}',
                        icon: Icons.report_problem_outlined,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Points progress ────────────────────────────────────
                PointsGrowthChart(
                  totalPoints: gamif.totalPoints,
                  badges: gamif.badges
                      .map((b) => {'name': b.badgeName})
                      .toList(),
                ),
                const SizedBox(height: 12),

                // ── Reduction gauge ────────────────────────────────────
                ReductionGauge(
                  reductionPct: usage.reductionPct,
                  message: usage.reductionMsg,
                ),
                const SizedBox(height: 12),

                // ── Weekly bar chart ───────────────────────────────────
                if (usage.weeklyStats != null)
                  WeeklyUsageChart(weeklyData: usage.weeklyStats!),
                const SizedBox(height: 12),

                // ── Monthly trend ──────────────────────────────────────
                if (usage.monthlyStats != null)
                  MonthlyTrendChart(monthlyData: usage.monthlyStats!),
                const SizedBox(height: 12),

                // ── Category pie ───────────────────────────────────────
                if (usage.dailyStats != null &&
                    (usage.dailyStats!['byCategory'] as Map?)?.isNotEmpty == true)
                  CategoryPieChart(categoryData: usage.dailyStats!),
                const SizedBox(height: 20),

                // ── Quick actions ──────────────────────────────────────
                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: [
                    _QuickAction(
                        icon: Icons.add_circle_outline,
                        label: 'Log Usage',
                        color: AppTheme.primary,
                        onTap: () => Navigator.pushNamed(
                            context, AppRouter.tracker)),
                    _QuickAction(
                        icon: Icons.camera_alt_outlined,
                        label: 'Report',
                        color: AppTheme.warning,
                        onTap: () => Navigator.pushNamed(
                            context, AppRouter.reportWaste)),
                    _QuickAction(
                        icon: Icons.map_outlined,
                        label: 'Heatmap',
                        color: AppTheme.accent,
                        onTap: () => Navigator.pushNamed(
                            context, AppRouter.heatmap)),
                    _QuickAction(
                        icon: Icons.leaderboard_outlined,
                        label: 'Leaderboard',
                        color: Colors.orange,
                        onTap: () => Navigator.pushNamed(
                            context, AppRouter.leaderboard)),
                    _QuickAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'Chat',
                        color: Colors.teal,
                        onTap: () =>
                            Navigator.pushNamed(context, AppRouter.chat)),
                    _QuickAction(
                        icon: Icons.eco_outlined,
                        label: 'Awareness',
                        color: Colors.green,
                        onTap: () => Navigator.pushNamed(
                            context, AppRouter.awareness)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Recent reports ─────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Reports',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRouter.reportWaste),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                if (reports.myReports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No reports yet.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                else
                  ...reports.myReports.take(3).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _statusColor(r.status),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        r.description ?? 'No description',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text(r.status,
                                        style: TextStyle(
                                            color: _statusColor(r.status),
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                const SizedBox(height: 20),

                // ── Upcoming events ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Upcoming Events',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRouter.events),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                if (events.events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No upcoming events.',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  )
                else
                  ...events.events.take(2).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          onTap: () => Navigator.pushNamed(
                              context, AppRouter.eventDetail,
                              arguments: e.id),
                          child: Row(
                            children: [
                              const Icon(Icons.event,
                                  color: AppTheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    Text(
                                        '${e.participantCount} participants · ${e.locationName}',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED': return Colors.green;
      case 'REJECTED': return AppTheme.error;
      case 'CLEANED':  return AppTheme.accent;
      default:         return AppTheme.warning;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
