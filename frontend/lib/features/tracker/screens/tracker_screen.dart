import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/usage_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../dashboard/widgets/stats_charts.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Bottle',    'icon': Icons.local_drink},
    {'name': 'Bag',       'icon': Icons.shopping_bag_outlined},
    {'name': 'Straw',     'icon': Icons.coffee},
    {'name': 'Container', 'icon': Icons.takeout_dining_outlined},
    {'name': 'Cup',       'icon': Icons.emoji_food_beverage_outlined},
    {'name': 'Wrapper',   'icon': Icons.inventory_2_outlined},
    {'name': 'Other',     'icon': Icons.category_outlined},
  ];

  String _selectedCategory = 'Bottle';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAll() {
    final now = DateTime.now();
    final provider = context.read<UsageProvider>();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    provider.loadHistory();
    provider.loadDailyStats(dateStr);
    provider.loadWeeklyStats(now.year, _isoWeek(now));
    provider.loadMonthlyStats(now.year, now.month);
    provider.loadReduction(
        'week', '${now.year}-W${_isoWeek(now).toString().padLeft(2, '0')}');
  }

  int _isoWeek(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Future<void> _logUsage() async {
    final success = await context
        .read<UsageProvider>()
        .logUsage(_selectedCategory, _quantity);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usage logged! +5 points 🌱'),
          backgroundColor: AppTheme.primary,
        ),
      );
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plastic Tracker'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Log'),
            Tab(text: 'Stats'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer<UsageProvider>(
        builder: (context, provider, _) {
          return LoadingOverlay(
            isLoading: provider.isLoading,
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── Log tab ──────────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.error != null) ...[
                            ErrorBanner(
                                message: provider.error!,
                                onDismiss: provider.clearError),
                            const SizedBox(height: 16),
                          ],

                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Log Today\'s Usage',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                const Text(
                                    'Track every plastic item you use today',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                                const SizedBox(height: 20),

                                // Category grid
                                const Text('Select Item',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 10),
                                GridView.count(
                                  crossAxisCount: 4,
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 0.85,
                                  children: _categories.map((cat) {
                                    final isSelected =
                                        _selectedCategory == cat['name'];
                                    return GestureDetector(
                                      onTap: () => setState(() =>
                                          _selectedCategory =
                                              cat['name'] as String),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primary
                                              : Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primary
                                                : Colors.grey[300]!,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              cat['icon'] as IconData,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.textSecondary,
                                              size: 22,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              cat['name'] as String,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppTheme.textSecondary,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                // Quantity
                                const Text('Quantity',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _QuantityBtn(
                                      icon: Icons.remove,
                                      onTap: () => setState(() {
                                        if (_quantity > 1) _quantity--;
                                      }),
                                    ),
                                    const SizedBox(width: 24),
                                    Column(
                                      children: [
                                        Text(
                                          '$_quantity',
                                          style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary),
                                        ),
                                        Text(
                                          _selectedCategory.toLowerCase(),
                                          style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    _QuantityBtn(
                                      icon: Icons.add,
                                      onTap: () =>
                                          setState(() => _quantity++),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                AppButton(
                                  label: 'Log Usage (+5 pts)',
                                  isLoading: provider.isLoading,
                                  onPressed: _logUsage,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Today's summary
                          if (provider.dailyStats != null) ...[
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Today's Summary",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.recycling,
                                          color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${provider.dailyStats!['totalItems']} items used today',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  if (provider.reductionPct != null) ...[
                                    const SizedBox(height: 8),
                                    ReductionGauge(
                                        reductionPct: provider.reductionPct),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Stats tab ────────────────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Column(
                        children: [
                          if (provider.dailyStats != null &&
                              (provider.dailyStats!['byCategory']
                                      as Map?)
                                  ?.isNotEmpty ==
                                  true)
                            CategoryPieChart(
                                categoryData: provider.dailyStats!),
                          const SizedBox(height: 12),
                          if (provider.weeklyStats != null)
                            WeeklyUsageChart(
                                weeklyData: provider.weeklyStats!),
                          const SizedBox(height: 12),
                          if (provider.monthlyStats != null)
                            MonthlyTrendChart(
                                monthlyData: provider.monthlyStats!),
                          const SizedBox(height: 12),
                          ReductionGauge(
                            reductionPct: provider.reductionPct,
                            message: provider.reductionMsg,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── History tab ──────────────────────────────────────
                provider.history.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64,
                                color: AppTheme.textSecondary),
                            SizedBox(height: 12),
                            Text('No usage logged yet',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.history.length,
                        itemBuilder: (context, index) {
                          final e = provider.history[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.recycling,
                                        color: AppTheme.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.itemCategory
                                              .substring(0, 1)
                                              .toUpperCase() +
                                              e.itemCategory.substring(1),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(e.entryDate,
                                            style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '×${e.quantity}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuantityBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QuantityBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
    );
  }
}
