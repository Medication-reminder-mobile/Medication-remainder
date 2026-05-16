import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/intake_log_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/intake_log_provider.dart';
import '../../services/db_service.dart';
import '../../services/voice_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _loading = true;
  Map<String, int> _stats = const {'perfect': 0, 'partial': 0, 'missed': 0};
  int _currentStreak = 0;
  List<double> _weeklyPulse = const [85, 90, 78, 95, 88, 70, 92];
  Map<int, String> _monthDayStatus = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final s = await DbService.instance.getMonthlyStats(
        userId,
        now.year,
        now.month,
      );
      final streak = await DbService.instance.getCurrentStreak(userId);
      final logs = await DbService.instance.getLogsByUser(userId);
      final weekly = _buildWeeklyPulse(logs, now);      final monthStatus = _buildMonthDayStatus(logs, now);
      if (!mounted) return;
      setState(() {
        _stats = s;
        _currentStreak = streak;
        _weeklyPulse = weekly;
        _monthDayStatus = monthStatus;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _voiceSummary() async {
    final adherence = context.read<IntakeLogProvider>().adherenceRate;
    final pct = (adherence * 100).round();
    final perfect = _stats['perfect'] ?? 0;
    final missed = _stats['missed'] ?? 0;
    final summary =
        'Your adherence report. Overall adherence is $pct percent. '
        'You had $perfect perfect days and $missed missed days this month. Keep it up!';
    await VoiceService.instance.speak(summary);
  }

  List<double> _buildWeeklyPulse(List<IntakeLogModel> logs, DateTime now) {
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final byDate = <String, List<IntakeLogModel>>{};
    for (final log in logs) {
      final date = DateTime.tryParse(log.date);
      if (date == null || date.isBefore(start)) continue;
      byDate.putIfAbsent(log.date, () => []).add(log);
    }

    return List<double>.generate(7, (i) {
      final day = start.add(Duration(days: i));
      final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final entries = byDate[key] ?? const [];
      if (entries.isEmpty) return 0;
      final taken = entries.where((e) => e.status == 'taken').length;
      return (taken / entries.length) * 100;
    });
  }

  Map<int, String> _buildMonthDayStatus(List<IntakeLogModel> logs, DateTime now) {
    final byDate = <String, List<IntakeLogModel>>{};
    for (final log in logs) {
      final date = DateTime.tryParse(log.date);
      if (date == null || date.year != now.year || date.month != now.month) continue;
      byDate.putIfAbsent(log.date, () => []).add(log);
    }
    final result = <int, String>{};
    byDate.forEach((date, entries) {
      final parsed = DateTime.tryParse(date);
      if (parsed == null) return;
      final taken = entries.where((e) => e.status == 'taken').length;
      if (taken == entries.length) {
        result[parsed.day] = 'perfect';
      } else if (taken > 0) {
        result[parsed.day] = 'partial';
      } else {
        result[parsed.day] = 'missed';
      }
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final adherence = context.watch<IntakeLogProvider>().adherenceRate;
    final pct = (adherence * 100).round();
    final perfect = _stats['perfect'] ?? 0;
    final partial = _stats['partial'] ?? 0;
    final missed = _stats['missed'] ?? 0;
    final now = DateTime.now();
    final monthName = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][now.month - 1];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('MedRemind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Adherence Reports',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review your medication compliance and trends.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _voiceSummary,
                          icon: const Icon(Icons.volume_up_outlined, size: 18),
                          label: const Text('Voice Summary'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Export coming soon'),
                                ),
                              ),
                          icon: const Icon(Icons.upload_outlined, size: 18),
                          label: const Text('Export PDF'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'CURRENT STREAK', value: '$_currentStreak', sub: 'days')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'BEST WEEK',
                          value: '100',
                          sub: '% adherence',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'OVERALL ADHERENCE',
                          value: '$pct',
                          sub: '% avg.',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'MISSED DOSES',
                          value: '$missed',
                          sub: 'this month',
                          valueColor: missed > 0 ? AppColors.missedAlert : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekly trend chart
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Weekly Trend',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            _Legend(color: AppColors.primary, label: 'Adhered'),
                            const SizedBox(width: 12),
                            _Legend(
                              color: AppColors.inactiveUpcoming,
                              label: 'Goal',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (v) => FlLine(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.3),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      const days = [
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                        'Sat',
                                        'Sun',
                                      ];
                                      final i = v.toInt();
                                      if (i < 0 || i >= days.length)
                                        return const SizedBox.shrink();
                                      return Text(
                                        days[i],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 3,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (_, __, ___, ____) =>
                                        FlDotCirclePainter(
                                          radius: 4,
                                          color: AppColors.primary,
                                          strokeWidth: 0,
                                        ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                                  spots: List.generate(_weeklyPulse.length, (i) => FlSpot(i.toDouble(), _weeklyPulse[i])),
                                ),
                                LineChartBarData(
                                  isCurved: false,
                                  color: AppColors.inactiveUpcoming,
                                  barWidth: 1.5,
                                  dashArray: [4, 4],
                                  dotData: const FlDotData(show: false),
                                  spots: const [
                                    FlSpot(0, 100),
                                    FlSpot(1, 100),
                                    FlSpot(2, 100),
                                    FlSpot(3, 100),
                                    FlSpot(4, 100),
                                    FlSpot(5, 100),
                                    FlSpot(6, 100),
                                  ],
                                ),
                              ],
                              minY: 0,
                              maxY: 110,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monthly consistency
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          color: Colors.black12,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Consistency',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          monthName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatRow(
                              label: 'Perfect Days',
                              value: '$perfect',
                              color: AppColors.primary,
                            ),
                            _StatRow(
                              label: 'Partial Days',
                              value: '$partial',
                              color: AppColors.warningRefill,
                            ),
                            _StatRow(
                              label: 'Missed Days',
                              value: '$missed',
                              color: AppColors.missedAlert,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _CalendarHeatmap(
                          month: now,
                          dayStatus: _monthDayStatus,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  pct >= 90
                                      ? "You're on the right track! Maintaining 90%+ adherence significantly improves clinical outcomes."
                                      : "Keep going! Try to take all your medications on time to improve your adherence.",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.valueColor,
  });
  final String label;
  final String value;
  final String sub;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _CalendarHeatmap extends StatelessWidget {
  const _CalendarHeatmap({required this.month, required this.dayStatus});

  final DateTime month;
  final Map<int, String> dayStatus;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final leading = firstWeekday - 1; // Mon-based grid
    final totalCells = leading + daysInMonth;
    final trailing = (7 - (totalCells % 7)) % 7;

    Color dayColor(int? day) {
      if (day == null) return Colors.transparent;
      final status = dayStatus[day];
      if (status == 'perfect') return AppColors.primary.withValues(alpha: 0.95);
      if (status == 'partial') return AppColors.warningRefill.withValues(alpha: 0.9);
      if (status == 'missed') return AppColors.missedAlert.withValues(alpha: 0.9);
      return Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4);
    }

    final cells = <int?>[
      ...List<int?>.filled(leading, null),
      ...List<int?>.generate(daysInMonth, (i) => i + 1),
      ...List<int?>.filled(trailing, null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Calendar Heatmap',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, i) {
            final day = cells[i];
            return Container(
              decoration: BoxDecoration(
                color: dayColor(day),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: day == null
                  ? null
                  : Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dayStatus[day] == null ? AppColors.textSecondary : Colors.white,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}
