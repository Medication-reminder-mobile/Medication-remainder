import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/rbc_entry_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rbc_provider.dart';

class RbcDashboardScreen extends StatefulWidget {
  const RbcDashboardScreen({super.key});

  @override
  State<RbcDashboardScreen> createState() => _RbcDashboardScreenState();
}

class _RbcDashboardScreenState extends State<RbcDashboardScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.id == null) return;
    await context.read<RbcProvider>().loadEntries(user!.id!);
  }

  @override
  Widget build(BuildContext context) {
    final rbcProvider = context.watch<RbcProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Menu not implemented'))),
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
        ),
        title: const Text('MedRemind'),
        actions: [
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice not implemented')),
            ),
            icon: const Icon(Icons.mic_none_outlined),
            tooltip: 'Voice',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntrySheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add RBC entry',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Screen title
            Semantics(
              header: true,
              child: Text(
                'RBC Dashboard',
                style: AppTextStyles.heading(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor your red blood cell health over time.',
              style: AppTextStyles.body(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Gradient banner
            const _GradientBanner(),
            const SizedBox(height: 20),

            if (rbcProvider.isLoading) ...[
              _ShimmerGrid(),
            ] else if (rbcProvider.entries.isEmpty) ...[
              _EmptyState(),
            ] else ...[
              // Latest reading section
              Text('Latest Reading', style: AppTextStyles.subheading(context)),
              const SizedBox(height: 12),
              _MetricGrid(entry: rbcProvider.latest!),
              const SizedBox(height: 20),

              // Chart
              if (rbcProvider.entries.length >= 2) ...[
                _ChartCard(entries: rbcProvider.entries),
                const SizedBox(height: 20),
              ],

              // History
              Text('History', style: AppTextStyles.subheading(context)),
              const SizedBox(height: 12),
              ...rbcProvider.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryItem(
                    entry: e,
                    onDelete: () async {
                      if (e.id == null) return;
                      await context.read<RbcProvider>().deleteEntry(e.id!);
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEntrySheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddEntrySheet(),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient Banner
// ---------------------------------------------------------------------------

class _GradientBanner extends StatelessWidget {
  const _GradientBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track Your Blood Health',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Monitor RBC, hemoglobin and hematocrit trends.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.bloodtype_outlined, color: Colors.white, size: 44),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric Grid (2x2)
// ---------------------------------------------------------------------------

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.entry});

  final RbcEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final rbcStatus = RbcRanges.statusFor(
      entry.rbcCount,
      RbcRanges.rbcMin,
      RbcRanges.rbcMax,
    );
    final hgbStatus = RbcRanges.statusFor(
      entry.hemoglobin,
      RbcRanges.hgbMin,
      RbcRanges.hgbMax,
    );
    final hctStatus = RbcRanges.statusFor(
      entry.hematocrit,
      RbcRanges.hctMin,
      RbcRanges.hctMax,
    );
    final mcvStatus = RbcRanges.statusFor(
      entry.mcv,
      RbcRanges.mcvMin,
      RbcRanges.mcvMax,
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'RBC Count',
                value: entry.rbcCount.toStringAsFixed(2),
                unit: 'M/µL',
                status: rbcStatus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Hemoglobin',
                value: entry.hemoglobin.toStringAsFixed(1),
                unit: 'g/dL',
                status: hgbStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Hematocrit',
                value: entry.hematocrit.toStringAsFixed(1),
                unit: '%',
                status: hctStatus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'MCV',
                value: entry.mcv.toStringAsFixed(1),
                unit: 'fL',
                status: mcvStatus,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
  });

  final String label;
  final String value;
  final String unit;
  final RbcStatus status;

  Color get _statusColor {
    switch (status) {
      case RbcStatus.normal:
        return AppColors.primary;
      case RbcStatus.low:
        return AppColors.missedAlert;
      case RbcStatus.high:
        return AppColors.warningRefill;
    }
  }

  String get _statusLabel {
    switch (status) {
      case RbcStatus.normal:
        return 'Normal';
      case RbcStatus.low:
        return 'Low';
      case RbcStatus.high:
        return 'High';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value $unit, status: $_statusLabel',
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Text(label, style: AppTextStyles.caption(context)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: AppTextStyles.caption(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _statusLabel,
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart Card
// ---------------------------------------------------------------------------

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.entries});

  final List<RbcEntryModel> entries;

  @override
  Widget build(BuildContext context) {
    // Take up to last 7 entries, reversed so oldest is first (left on chart)
    final chartEntries = entries.length > 7
        ? entries.sublist(0, 7).reversed.toList()
        : entries.reversed.toList();

    final spots = chartEntries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.rbcCount);
    }).toList();

    final minY =
        (chartEntries.map((e) => e.rbcCount).reduce((a, b) => a < b ? a : b) -
                0.5)
            .clamp(0.0, double.infinity);
    final maxY =
        chartEntries.map((e) => e.rbcCount).reduce((a, b) => a > b ? a : b) +
        0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('RBC Count Trend', style: AppTextStyles.subheading(context)),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.inactiveUpcoming.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
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
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= chartEntries.length) {
                          return const SizedBox.shrink();
                        }
                        final date = chartEntries[idx].recordedAt;
                        final label = _abbrevDate(date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 3.5,
                            color: AppColors.primary,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _abbrevDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ---------------------------------------------------------------------------
// History Item
// ---------------------------------------------------------------------------

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.entry, required this.onDelete});

  final RbcEntryModel entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDate(entry.recordedAt);

    return Semantics(
      label: 'RBC entry from $dateStr',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bloodtype_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RBC ${entry.rbcCount.toStringAsFixed(2)} M/µL  •  '
                    'Hgb ${entry.hemoglobin.toStringAsFixed(1)} g/dL  •  '
                    'Hct ${entry.hematocrit.toStringAsFixed(1)}%',
                    style: AppTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Options',
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.missedAlert),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ---------------------------------------------------------------------------
// Shimmer Loading Skeleton
// ---------------------------------------------------------------------------

class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ShimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ShimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No RBC records yet',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bloodtype_outlined,
                size: 64,
                color: AppColors.inactiveUpcoming,
              ),
              const SizedBox(height: 16),
              Text(
                'No RBC records yet.',
                style: AppTextStyles.subheading(context),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first entry.',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Entry Bottom Sheet
// ---------------------------------------------------------------------------

class _AddEntrySheet extends StatefulWidget {
  const _AddEntrySheet();

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _rbcCtrl = TextEditingController();
  final _hgbCtrl = TextEditingController();
  final _hctCtrl = TextEditingController();
  final _mcvCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _rbcCtrl.dispose();
    _hgbCtrl.dispose();
    _hctCtrl.dispose();
    _mcvCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final user = context.read<AuthProvider>().currentUser;
    if (user?.id == null) {
      setState(() => _saving = false);
      return;
    }

    final entry = RbcEntryModel(
      userId: user!.id!,
      rbcCount: double.parse(_rbcCtrl.text.trim()),
      hemoglobin: double.parse(_hgbCtrl.text.trim()),
      hematocrit: double.parse(_hctCtrl.text.trim()),
      mcv: double.parse(_mcvCtrl.text.trim()),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      recordedAt: DateTime.now(),
    );

    await context.read<RbcProvider>().addEntry(entry);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add RBC Entry', style: AppTextStyles.subheading(context)),
              const SizedBox(height: 20),

              _NumericField(
                controller: _rbcCtrl,
                label: 'RBC Count (million/µL)',
                hint: 'e.g. 4.7',
                min: 0.1,
                max: 20.0,
              ),
              const SizedBox(height: 14),

              _NumericField(
                controller: _hgbCtrl,
                label: 'Hemoglobin (g/dL)',
                hint: 'e.g. 13.5',
                min: 1.0,
                max: 30.0,
              ),
              const SizedBox(height: 14),

              _NumericField(
                controller: _hctCtrl,
                label: 'Hematocrit (%)',
                hint: 'e.g. 41.0',
                min: 1.0,
                max: 100.0,
              ),
              const SizedBox(height: 14),

              _NumericField(
                controller: _mcvCtrl,
                label: 'MCV (fL)',
                hint: 'e.g. 90.0',
                min: 40.0,
                max: 200.0,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Fasting sample',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Numeric Field helper
// ---------------------------------------------------------------------------

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.min,
    required this.max,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        final n = double.tryParse(v.trim());
        if (n == null) return 'Enter a valid number';
        if (n < min || n > max) return 'Must be between $min and $max';
        return null;
      },
    );
  }
}
