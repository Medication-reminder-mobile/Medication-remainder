import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_helpers.dart';
import '../../models/doctor_note_model.dart';
import '../../models/intake_log_model.dart';
import '../../models/medication_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/intake_log_provider.dart';
import '../../providers/medication_provider.dart';
import '../../services/db_service.dart';
import '../../widgets/pill_icon_widget.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  bool _loaded = false;
  DoctorNoteModel? _note;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    final intakeLogProvider = context.read<IntakeLogProvider>();
    final user = authProvider.currentUser;
    if (user?.id == null) return;
    await medicationProvider.loadMedications(user!.id!);
    await intakeLogProvider.loadTodayLogs(user.id!);
    await intakeLogProvider.loadAdherenceStats(user.id!);
    final notes = await DbService.instance.getNotesByPatient(user.id!);
    if (!mounted) return;
    setState(() => _note = notes.isEmpty ? null : notes.first);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final medsProvider = context.watch<MedicationProvider>();
    final logsProvider = context.watch<IntakeLogProvider>();

    final name = auth.currentUser?.name.split(' ').firstOrNull ?? 'there';
    final todayLogs = logsProvider.todayLogs;
    final upcoming = todayLogs.where((l) => l.status == 'upcoming').toList(growable: false);
    final left = upcoming.length;
    final percent = logsProvider.adherenceRate.clamp(0.0, 1.0).toDouble();

    final refillLow = medsProvider.medications.where((m) => m.refillCount < 5).toList(growable: false);

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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Good morning, $name', style: AppTextStyles.heading(context).copyWith(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              left == 0
                  ? 'All medications taken for today!'
                  : 'You have $left medication${left == 1 ? '' : 's'} left for today.',
              style: AppTextStyles.body(context).copyWith(
                color: left == 0 ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Row 1: stats + actions
            Row(
              children: [
                Expanded(
                  child: _Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularPercentIndicator(
                          radius: 46,
                          lineWidth: 8,
                          percent: percent,
                          circularStrokeCap: CircularStrokeCap.round,
                          // Color shifts red when adherence is low
                          progressColor: percent >= 0.7
                              ? AppColors.primary
                              : percent >= 0.4
                                  ? AppColors.warningRefill
                                  : AppColors.missedAlert,
                          backgroundColor: AppColors.inactiveUpcoming.withValues(alpha: 0.25),
                          center: Text(
                            '${(percent * 100).round()}%',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Daily Goal', style: AppTextStyles.caption(context)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/meds/add'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Med'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/log'),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Log Intake'),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Text("Today's Schedule", style: AppTextStyles.subheading(context)),
                const Spacer(),
                TextButton(onPressed: () => context.go('/log'), child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 10),

            if (todayLogs.isEmpty)
              _Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 40, color: AppColors.inactiveUpcoming.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text('No medications scheduled today', style: AppTextStyles.body(context).copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 126,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    final log = todayLogs[i];
                    return _ScheduleCard(
                      log: log,
                      medName: medsProvider.medications
                          .where((m) => m.id == log.medicationId)
                          .firstOrNull
                          ?.name,
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: todayLogs.length.clamp(0, 8),
                ),
              ),

            const SizedBox(height: 18),
            _GradientBanner(
              title: 'Weekly Health Report',
              subtitle: 'Your adherence is 12% higher than last week. Great job!',
              actionText: 'View Report',
              onAction: () => context.go('/reports'),
              trailing: const Icon(Icons.show_chart, color: Colors.white, size: 44),
            ),

            if (_note != null) ...[
              const SizedBox(height: 14),
              _Card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Doctor's Note", style: AppTextStyles.subheading(context)),
                          const SizedBox(height: 6),
                          Text(_note!.note, style: AppTextStyles.body(context)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],

            if (refillLow.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Card(
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: AppColors.warningRefill),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your ${refillLow.first.name} prescription only has ${refillLow.first.refillCount} doses remaining.',
                        style: AppTextStyles.body(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordering not implemented'))),
                      child: const Text('Order Now'),
                    )
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),
            Text("Today's Timeline", style: AppTextStyles.subheading(context)),
            const SizedBox(height: 10),

            if (isDark) ...[
              _GroupHeader(icon: Icons.wb_sunny_outlined, title: 'Morning'),
              ..._timelineItems(context, medsProvider.medications, todayLogs, group: 'Morning'),
              const SizedBox(height: 8),
              _GroupHeader(icon: Icons.wb_twilight_outlined, title: 'Afternoon'),
              ..._timelineItems(context, medsProvider.medications, todayLogs, group: 'Afternoon'),
              const SizedBox(height: 8),
              _GroupHeader(icon: Icons.nights_stay_outlined, title: 'Evening'),
              ..._timelineItems(context, medsProvider.medications, todayLogs, group: 'Evening'),
              const SizedBox(height: 12),
              _Card(
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.warningRefill),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Daily Insight\nTaking Vitamin D with a meal improves absorption.',
                        style: AppTextStyles.body(context),
                      ),
                    ),
                  ],
                ),
              )
            ] else ...[
              ..._timelineItems(context, medsProvider.medications, todayLogs),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _timelineItems(
    BuildContext context,
    List<MedicationModel> meds,
    List<IntakeLogModel> logs, {
    String? group,
  }) {
    MedicationModel? findMed(int id) => meds.where((m) => m.id == id).firstOrNull;

    final now = DateTime.now();
    final sorted = [...logs]..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    final upcomingList = sorted.where((l) => l.status == 'upcoming').toList(growable: false);
    final next = upcomingList.isEmpty ? null : upcomingList.first;

    bool inGroup(IntakeLogModel l) {
      if (group == null) return true;
      final due = DateHelpers.combineDateAndTime(now, l.scheduledTime);
      final h = due.hour;
      return switch (group) {
        'Morning' => h < 12,
        'Afternoon' => h >= 12 && h < 18,
        _ => h >= 18,
      };
    }

    final filtered = sorted.where(inGroup).toList(growable: false);

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'No medications in this period.',
            style: AppTextStyles.body(context).copyWith(color: AppColors.textSecondary),
          ),
        ),
      ];
    }

    return filtered.map((log) {
      final med = findMed(log.medicationId);
      final due = DateHelpers.combineDateAndTime(now, log.scheduledTime);
      final minutes = due.difference(now).inMinutes;
      final isUpcoming = log.status == 'upcoming';
      final highlight = (next?.id == log.id) && isUpcoming && minutes >= 0 && minutes <= 15;
      // Active = upcoming and not yet missed (due in future or within grace window)
      final isActive = isUpcoming && minutes > -30;
      final isOverdue = isUpcoming && minutes <= -30;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Active indicator stripe
              if (isActive && !highlight)
                Container(
                  width: 4,
                  height: 50,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              if (isOverdue)
                Container(
                  width: 4,
                  height: 50,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.missedAlert,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              PillIcon(
                shape: med?.pillShape ?? 'capsule',
                colorHex: med?.pillColor ?? '#00897B',
                size: 32,
                semanticsLabel: 'Medication icon',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (highlight)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('IN 15 MINS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    if (isOverdue)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.missedAlert.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('OVERDUE', style: TextStyle(color: AppColors.missedAlert, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    Text(med?.name ?? 'Medication', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      '${med?.dosageStrength ?? ''}${med?.dosageUnit ?? ''} • ${_fmtTime(log.scheduledTime)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusWidget(log: log),
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: 'More options',
                child: IconButton(
                  onPressed: () => _showLogMenu(context, log),
                  icon: const Icon(Icons.more_vert),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(growable: false);
  }

  String _fmtTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p.first) ?? 0;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    final dt = DateTime(2000, 1, 1, h, m);
    final hour12 = (dt.hour % 12 == 0) ? 12 : (dt.hour % 12);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _showLogMenu(BuildContext context, IntakeLogModel log) async {
    final provider = context.read<IntakeLogProvider>();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: AppColors.primary),
              title: const Text('Mark taken'),
              onTap: () => Navigator.pop(context, 'taken'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: AppColors.missedAlert),
              title: const Text('Mark missed'),
              onTap: () => Navigator.pop(context, 'missed'),
            ),
            // Allow un-marking if already taken or missed
            if (log.status == 'taken' || log.status == 'missed')
              ListTile(
                leading: const Icon(Icons.undo_outlined, color: AppColors.inactiveUpcoming),
                title: const Text('Reset to upcoming'),
                onTap: () => Navigator.pop(context, 'reset'),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'taken') {
      await provider.markTaken(log);
    } else if (action == 'missed') {
      await provider.markMissed(log);
    } else if (action == 'reset') {
      await provider.markUpcoming(log); // ensure markUpcoming exists in your provider
    }
  }
}

class _StatusWidget extends StatelessWidget {
  const _StatusWidget({required this.log});

  final IntakeLogModel log;

  @override
  Widget build(BuildContext context) {
    switch (log.status) {
      case 'taken':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text('Taken', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
        );
      case 'missed':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.missedAlert.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text('Missed', style: TextStyle(color: AppColors.missedAlert, fontWeight: FontWeight.w800, fontSize: 12)),
        );
      default:
        return SizedBox(
          height: 36,
          child: OutlinedButton(
            onPressed: () => context.read<IntakeLogProvider>().markTaken(log),
            child: const Text('Log'),
          ),
        );
    }
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.log, this.medName});

  final IntakeLogModel log;
  final String? medName;

  @override
  Widget build(BuildContext context) {
    final icon = log.status == 'taken'
        ? const Icon(Icons.check, color: Colors.white, size: 16)
        : log.status == 'missed'
            ? const Icon(Icons.warning_amber, color: Colors.white, size: 16)
            : const Icon(Icons.schedule, color: Colors.white, size: 16);
    final bg = log.status == 'taken'
        ? AppColors.primary
        : log.status == 'missed'
            ? AppColors.missedAlert
            : AppColors.inactiveUpcoming;

    return Semantics(
      label: 'Schedule item: ${medName ?? 'Medication'}, ${log.status}',
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          // Highlight active (upcoming) cards with a subtle border
          border: log.status == 'upcoming'
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
              : null,
          boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_fmtTime(log.scheduledTime), style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              medName ?? 'Medication',
              style: const TextStyle(fontWeight: FontWeight.w900),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              log.status == 'taken'
                  ? 'Taken ✓'
                  : log.status == 'missed'
                      ? 'Missed'
                      : 'Upcoming',
              style: TextStyle(
                color: log.status == 'taken'
                    ? AppColors.primary
                    : log.status == 'missed'
                        ? AppColors.missedAlert
                        : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Center(child: icon),
            )
          ],
        ),
      ),
    );
  }

  String _fmtTime(String hhmm) {
    final p = hhmm.split(':');
    final h = int.tryParse(p.first) ?? 0;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    final dt = DateTime(2000, 1, 1, h, m);
    final hour12 = (dt.hour % 12 == 0) ? 12 : (dt.hour % 12);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12),
        ],
      ),
      child: child,
    );
  }
}

class _GradientBanner extends StatelessWidget {
  const _GradientBanner({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onAction,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onAction;
  final Widget trailing;

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
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(subtitle, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(actionText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inactiveUpcoming),
          const SizedBox(width: 8),
          Text(title, style: AppTextStyles.subheading(context)),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}