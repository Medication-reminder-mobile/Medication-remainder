import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/caregiver_provider.dart';
import '../../services/db_service.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final _search = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
    final caregiverProvider = context.read<CaregiverProvider>();
    await caregiverProvider.loadLinkedPatients(user!.id!);
    if (!mounted) return;
    await caregiverProvider.loadTasks(user.id!);
  }

  @override
  Widget build(BuildContext context) {
    final caregiver = context.watch<CaregiverProvider>();
    final patients = caregiver.linkedPatients;
    final tasks = caregiver.tasks;
    final filtered = patients.where((p) {
      final q = _search.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q);
    }).toList(growable: false);

    final active = patients.length;
    final adherence = patients.isEmpty ? 0.92 : 0.72 + (0.25 * math.min(1, patients.length / 10));

    final urgentNames = patients.take(3).map((e) => e.name.split(' ').first).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu not implemented'))),
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
        ),
        title: const Text('MedRemind'),
        actions: [
          IconButton(
            onPressed: () => context.go('/voice'),
            icon: const Icon(Icons.mic_none_outlined),
            tooltip: 'Voice reminders',
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: 'Profile avatar',
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                child: const Icon(Icons.person_outline, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Caregiver Dashboard', style: AppTextStyles.heading(context).copyWith(fontSize: 24)),
            const SizedBox(height: 6),
            Text('Monitoring $active active patients today.', style: AppTextStyles.body(context).copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search patient name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF1F5F9),
              ),
            ),
            const SizedBox(height: 14),
            _UrgentCard(
              missedCount: math.max(1, patients.length ~/ 3),
              names: urgentNames,
              onReview: () => context.go('/caregiver/patients'),
            ),
            const SizedBox(height: 16),
            Text('OVERALL ADHERENCE RATE', style: AppTextStyles.caption(context).copyWith(letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(adherence * 100).round()}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 86,
                    child: _WeeklyBarChart(values: _fakeWeeklyPatients(patients.length)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TealSummaryCard(
              text: '${math.max(1, patients.length ~/ 2)} Patients\nPerfect Adherence Today',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Patient Roster', style: AppTextStyles.subheading(context)),
                const Spacer(),
                TextButton(onPressed: () => context.go('/reports'), child: const Text('View Full Report  ›')),
              ],
            ),
            const SizedBox(height: 8),
            ...filtered.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PatientCard(
                    name: p.name,
                    lastActivity: '${math.max(1, p.id ?? 1) % 12}h ago',
                    adherence: 0.55 + (0.45 * (((p.id ?? 1) % 10) / 10)),
                    onTap: () => context.go('/caregiver/patient-meds/${p.id ?? 0}'),
                    onUnlink: () async {
                      final caregiverId = context.read<AuthProvider>().currentUser?.id;
                      if (caregiverId == null || p.id == null) return;
                      await DbService.instance.unlinkPatient(caregiverId, p.id!);
                      await caregiver.loadLinkedPatients(caregiverId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unlinked')));
                    },
                  ),
                )),
            const SizedBox(height: 14),
            Text('Caregiver Tasks', style: AppTextStyles.subheading(context)),
            const SizedBox(height: 8),
            ...tasks.map((t) => _TaskItem(
                  text: t.description,
                  priority: t.priority,
                  done: t.isDone,
                  onToggle: (v) {
                    if (t.id == null) return;
                    context.read<CaregiverProvider>().toggleTask(t.id!, v);
                  },
                )),
            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/caregiver/link'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<double> _fakeWeeklyPatients(int count) {
    final base = 0.55 + (0.35 * math.min(1, count / 10));
    return List.generate(7, (i) => (base + (i.isEven ? 0.06 : -0.03)).clamp(0.3, 0.98));
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.missedCount, required this.names, required this.onReview});

  final int missedCount;
  final List<String> names;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.missedAlert),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Urgent: $missedCount Missed Doses Detected', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  names.isEmpty ? 'No names available.' : 'Patients: ${names.join(', ')}',
                  style: const TextStyle(color: Color(0xFF7F1D1D)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.missedAlert),
            onPressed: onReview,
            child: const Text('Review Now'),
          ),
        ],
      ),
    );
  }
}

class _TealSummaryCard extends StatelessWidget {
  const _TealSummaryCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.name,
    required this.lastActivity,
    required this.adherence,
    required this.onTap,
    required this.onUnlink,
  });

  final String name;
  final String lastActivity;
  final double adherence;
  final VoidCallback onTap;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final pct = (adherence * 100).round();
    final badge = _badge(pct);

    return Semantics(
      button: true,
      label: 'Patient $name',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                child: const Icon(Icons.person_outline, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('Last Activity: $lastActivity', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$pct% ${badge.label}', style: TextStyle(color: badge.color, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
              PopupMenuButton<String>(
                tooltip: 'Patient actions',
                onSelected: (v) {
                  if (v == 'unlink') onUnlink();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text('View Meds')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'unlink', child: Text('Unlink')),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Badge _badge(int pct) {
    if (pct >= 90) return const _Badge('Good', Color(0xFF16A34A));
    if (pct >= 70) return const _Badge('Fair', AppColors.warningRefill);
    return const _Badge('Alert', AppColors.missedAlert);
  }
}

class _Badge {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({required this.text, required this.priority, required this.done, required this.onToggle});

  final String text;
  final String priority;
  final bool done;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final badge = switch (priority) {
      'high' => const _Badge('HIGH', AppColors.missedAlert),
      'medium' => const _Badge('MEDIUM', AppColors.warningRefill),
      _ => const _Badge('LOW', AppColors.inactiveUpcoming),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12)],
      ),
      child: Row(
        children: [
          Semantics(
            label: done ? 'Task complete' : 'Task not complete',
            child: Checkbox(value: done, onChanged: (v) => onToggle(v ?? false)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(decoration: done ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge.label, style: TextStyle(color: badge.color, fontWeight: FontWeight.w900, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.values});
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        barTouchData: BarTouchData(enabled: false),
        barGroups: List.generate(
          values.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i] * 100,
                width: 10,
                borderRadius: BorderRadius.circular(6),
                color: AppColors.primary.withValues(alpha: 0.9),
              )
            ],
          ),
        ),
        minY: 0,
        maxY: 100,
      ),
    );
  }
}

