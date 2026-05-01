import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

/// Weekly usage bar chart
class WeeklyUsageChart extends StatelessWidget {
  final Map<String, dynamic> weeklyData;
  const WeeklyUsageChart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final byPeriod = weeklyData['byPeriod'] as Map<String, dynamic>? ?? {};
    if (byPeriod.isEmpty) return const _EmptyChart(label: 'No weekly data');

    final entries = byPeriod.entries.toList();
    final maxVal = entries
        .map((e) => (e.value as num).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Week',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('Daily plastic items used',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxVal == 0 ? 10 : maxVal * 1.3,
                  barGroups: entries.asMap().entries.map((e) {
                    final val = (e.value.value as num).toDouble();
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          gradient: LinearGradient(
                            colors: [AppTheme.secondary, AppTheme.primary],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final key = entries[val.toInt()].key as String;
                          // Show last 3 chars (e.g. Mon, Tue or date)
                          final label = key.length > 5
                              ? key.substring(key.length - 5)
                              : key;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(label,
                                style: const TextStyle(fontSize: 9,
                                    color: AppTheme.textSecondary)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 9,
                              color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Monthly trend line chart
class MonthlyTrendChart extends StatelessWidget {
  final Map<String, dynamic> monthlyData;
  const MonthlyTrendChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final byPeriod = monthlyData['byPeriod'] as Map<String, dynamic>? ?? {};
    if (byPeriod.isEmpty) return const _EmptyChart(label: 'No monthly data');

    final entries = byPeriod.entries.toList();
    final spots = entries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value.value as num).toDouble());
    }).toList();

    final maxVal = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Month',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('Weekly plastic usage trend',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  maxY: maxVal == 0 ? 10 : maxVal * 1.3,
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.accent, AppTheme.primary],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary.withOpacity(0.2),
                            AppTheme.primary.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= entries.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(entries[idx].key,
                                style: const TextStyle(fontSize: 9,
                                    color: AppTheme.textSecondary)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 9,
                              color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category donut/pie chart
class CategoryPieChart extends StatefulWidget {
  final Map<String, dynamic> categoryData;
  const CategoryPieChart({super.key, required this.categoryData});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  static const List<Color> _colors = [
    AppTheme.primary,
    AppTheme.warning,
    AppTheme.accent,
    Colors.purple,
    Colors.indigo,
    Colors.red,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final byCategory = widget.categoryData['byCategory'] as Map<String, dynamic>? ?? {};
    if (byCategory.isEmpty) return const _EmptyChart(label: 'No category data');

    final entries = byCategory.entries.toList();
    final total = entries.fold(0.0, (sum, e) => sum + (e.value as num).toDouble());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('By Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Text('Today\'s plastic usage breakdown',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            _touchedIndex = response?.touchedSection
                                    ?.touchedSectionIndex ?? -1;
                          });
                        },
                      ),
                      sections: entries.asMap().entries.map((e) {
                        final isTouched = e.key == _touchedIndex;
                        final val = (e.value.value as num).toDouble();
                        final pct = total > 0 ? (val / total * 100) : 0;
                        return PieChartSectionData(
                          value: val,
                          color: _colors[e.key % _colors.length],
                          radius: isTouched ? 65 : 55,
                          title: '${pct.toStringAsFixed(0)}%',
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.asMap().entries.map((e) {
                      final val = (e.value.value as num).toInt();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: _colors[e.key % _colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.value.key.toString().capitalize(),
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('$val',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reduction percentage gauge
class ReductionGauge extends StatelessWidget {
  final double? reductionPct;
  final String? message;
  const ReductionGauge({super.key, this.reductionPct, this.message});

  @override
  Widget build(BuildContext context) {
    if (reductionPct == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message ?? 'No comparison data available yet',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isReduction = reductionPct! >= 0;
    final color = isReduction ? Colors.green : AppTheme.error;
    final icon = isReduction ? Icons.trending_down : Icons.trending_up;
    final label = isReduction ? 'Reduction' : 'Increase';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reductionPct!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text('$label vs last period',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin stats overview chart — reports by status
class ReportStatusChart extends StatelessWidget {
  final Map<String, int> statusCounts;
  const ReportStatusChart({super.key, required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    if (statusCounts.isEmpty) return const _EmptyChart(label: 'No report data');

    final statuses = ['PENDING', 'APPROVED', 'REJECTED', 'CLEANED'];
    final colors = [AppTheme.warning, Colors.green, AppTheme.error, AppTheme.accent];
    final total = statusCounts.values.fold(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reports Overview',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Total: $total reports',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...statuses.asMap().entries.map((e) {
              final count = statusCounts[e.value] ?? 0;
              final pct = total > 0 ? count / total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.value,
                            style: TextStyle(
                                fontSize: 12,
                                color: colors[e.key],
                                fontWeight: FontWeight.w600)),
                        Text('$count',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.toDouble(),
                        backgroundColor: colors[e.key].withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(colors[e.key]),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Points growth line chart for gamification
class PointsGrowthChart extends StatelessWidget {
  final int totalPoints;
  final List<Map<String, dynamic>> badges;
  const PointsGrowthChart({
    super.key,
    required this.totalPoints,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    // Milestone thresholds
    const milestones = [
      {'label': 'Eco Beginner', 'pts': 50},
      {'label': 'Plastic Warrior', 'pts': 200},
      {'label': 'Community Champion', 'pts': 500},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Points Progress',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('$totalPoints pts earned',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            ...milestones.map((m) {
              final target = m['pts'] as int;
              final label  = m['label'] as String;
              final pct    = (totalPoints / target).clamp(0.0, 1.0);
              final earned = totalPoints >= target;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          earned ? Icons.emoji_events : Icons.emoji_events_outlined,
                          color: earned ? Colors.amber : AppTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: earned ? Colors.amber[800] : AppTheme.textPrimary,
                              )),
                        ),
                        Text('$totalPoints / $target pts',
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.amber.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(
                            earned ? Colors.amber : Colors.amber.withOpacity(0.5)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String label;
  const _EmptyChart({required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bar_chart, size: 40, color: AppTheme.textSecondary),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
