import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/gamification_provider.dart';
import '../../../core/providers/usage_provider.dart';
import '../../../core/providers/report_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../dashboard/widgets/stats_charts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().loadProfile();
      context.read<ReportProvider>().loadMyReports();
      final now = DateTime.now();
      context.read<UsageProvider>().loadMonthlyStats(now.year, now.month);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Badges'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: Consumer3<GamificationProvider, UsageProvider, ReportProvider>(
        builder: (context, gamif, usage, reports, _) {
          return LoadingOverlay(
            isLoading: gamif.isLoading,
            child: Column(
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white24,
                        child: Text(
                          (auth.user?.displayName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.displayName ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              auth.user?.email ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _InfoChip(
                                    label: auth.user?.role ?? 'USER',
                                    color: Colors.white24),
                                const SizedBox(width: 8),
                                _InfoChip(
                                    label: '${gamif.totalPoints} pts',
                                    color: Colors.amber.withOpacity(0.3)),
                                const SizedBox(width: 8),
                                _InfoChip(
                                    label: 'Rank #${gamif.rank}',
                                    color: Colors.white24),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── Overview tab ─────────────────────────────────
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Column(
                              children: [
                                // Stats row
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatCard(
                                          label: 'Points',
                                          value: '${gamif.totalPoints}',
                                          icon: Icons.stars,
                                          color: AppTheme.warning),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatCard(
                                          label: 'Rank',
                                          value: '#${gamif.rank}',
                                          icon: Icons.leaderboard,
                                          color: AppTheme.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatCard(
                                          label: 'Badges',
                                          value: '${gamif.badges.length}',
                                          icon: Icons.emoji_events,
                                          color: Colors.amber),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _StatCard(
                                          label: 'Reports',
                                          value:
                                              '${reports.myReports.length}',
                                          icon: Icons.report_problem_outlined,
                                          color: Colors.orange),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Points progress
                                PointsGrowthChart(
                                  totalPoints: gamif.totalPoints,
                                  badges: gamif.badges
                                      .map((b) => {'name': b.badgeName})
                                      .toList(),
                                ),
                                const SizedBox(height: 12),

                                // Monthly usage chart
                                if (usage.monthlyStats != null)
                                  MonthlyTrendChart(
                                      monthlyData: usage.monthlyStats!),
                                const SizedBox(height: 16),

                                // Quick links
                                AppCard(
                                  padding: EdgeInsets.zero,
                                  child: Column(
                                    children: [
                                      _MenuItem(
                                        icon: Icons.leaderboard_outlined,
                                        label: 'Leaderboard',
                                        trailing: 'Rank #${gamif.rank}',
                                        onTap: () => Navigator.pushNamed(
                                            context, AppRouter.leaderboard),
                                      ),
                                      const Divider(height: 1),
                                      _MenuItem(
                                        icon: Icons.eco_outlined,
                                        label: 'Awareness',
                                        onTap: () => Navigator.pushNamed(
                                            context, AppRouter.awareness),
                                      ),
                                      const Divider(height: 1),
                                      _MenuItem(
                                        icon: Icons.map_outlined,
                                        label: 'Pollution Heatmap',
                                        onTap: () => Navigator.pushNamed(
                                            context, AppRouter.heatmap),
                                      ),
                                      const Divider(height: 1),
                                      _MenuItem(
                                        icon: Icons.chat_bubble_outline,
                                        label: 'Community Chat',
                                        onTap: () => Navigator.pushNamed(
                                            context, AppRouter.chat),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Badges tab ───────────────────────────────────
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (gamif.badges.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Column(
                                        children: [
                                          Icon(Icons.emoji_events_outlined,
                                              size: 64,
                                              color: AppTheme.textSecondary),
                                          SizedBox(height: 12),
                                          Text('No badges yet',
                                              style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 16)),
                                          SizedBox(height: 8),
                                          Text(
                                              'Earn 50 points to get your first badge!',
                                              style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 13),
                                              textAlign: TextAlign.center),
                                        ],
                                      ),
                                    ),
                                  )
                                else ...[
                                  Text(
                                      '${gamif.badges.length} badge${gamif.badges.length == 1 ? '' : 's'} earned',
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13)),
                                  const SizedBox(height: 16),
                                  ...gamif.badges.map((b) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12),
                                        child: AppCard(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                    colors: [
                                                      Colors.amber,
                                                      Colors.orange
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12),
                                                ),
                                                child: const Icon(
                                                    Icons.emoji_events,
                                                    color: Colors.white,
                                                    size: 28),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(b.badgeName,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15)),
                                                    Text(
                                                        'Awarded ${_formatDate(b.awardedAt)}',
                                                        style: const TextStyle(
                                                            color: AppTheme
                                                                .textSecondary,
                                                            fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.verified,
                                                  color: Colors.amber),
                                            ],
                                          ),
                                        ),
                                      )),
                                ],

                                const SizedBox(height: 20),
                                const Text('All Badges',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 12),
                                ..._allBadges(gamif.badges
                                    .map((b) => b.badgeName)
                                    .toList()),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Activity tab ─────────────────────────────────
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 700),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('My Waste Reports',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                const SizedBox(height: 12),
                                if (reports.myReports.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text('No reports submitted yet',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary)),
                                    ),
                                  )
                                else
                                  ...reports.myReports.map((r) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: AppCard(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color:
                                                      _statusColor(r.status),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        r.description ??
                                                            'No description',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500)),
                                                    Text(
                                                        'Lat: ${r.latitude.toStringAsFixed(4)}, '
                                                        'Lng: ${r.longitude.toStringAsFixed(4)}',
                                                        style: const TextStyle(
                                                            color: AppTheme
                                                                .textSecondary,
                                                            fontSize: 11)),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _statusColor(r.status)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(r.status,
                                                    style: TextStyle(
                                                        color: _statusColor(
                                                            r.status),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _allBadges(List<String> earned) {
    final all = [
      {
        'name': 'Eco Beginner',
        'desc': 'Earn 50 points',
        'pts': 50,
        'icon': Icons.eco
      },
      {
        'name': 'Plastic Warrior',
        'desc': 'Earn 200 points',
        'pts': 200,
        'icon': Icons.shield
      },
      {
        'name': 'Community Champion',
        'desc': 'Earn 500 points',
        'pts': 500,
        'icon': Icons.emoji_events
      },
      {
        'name': 'Participant',
        'desc': 'Attend your first event',
        'pts': 0,
        'icon': Icons.people
      },
    ];

    return all.map((b) {
      final isEarned = earned.contains(b['name']);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEarned
                ? Colors.amber.withOpacity(0.08)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEarned
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(b['icon'] as IconData,
                  color: isEarned ? Colors.amber : Colors.grey, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['name'] as String,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isEarned
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary)),
                    Text(b['desc'] as String,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              if (isEarned)
                const Icon(Icons.check_circle, color: Colors.amber, size: 20)
              else
                const Icon(Icons.lock_outline,
                    color: AppTheme.textSecondary, size: 20),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
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

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(label),
      trailing: trailing != null
          ? Text(trailing!,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12))
          : const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
