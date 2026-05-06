import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/intake_log_provider.dart';
import '../../providers/medication_provider.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    final intakeProvider = context.read<IntakeLogProvider>();
    final medicationProvider = context.read<MedicationProvider>();
    await intakeProvider.loadTodayLogs(userId);
    await medicationProvider.loadMedications(userId);
  }

  Future<void> _logAllTaken() async {
    final provider = context.read<IntakeLogProvider>();
    final upcoming = provider.todayLogs
        .where((l) => l.status == 'upcoming')
        .toList();
    for (final log in upcoming) {
      await provider.markTaken(log);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All medications marked as taken')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IntakeLogProvider>();
    final medsProvider = context.watch<MedicationProvider>();
    final logs = provider.todayLogs;
    final done = logs.where((l) => l.status == 'taken').length;
    final total = logs.length;
    final now = DateTime.now();
    final dayName = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];
    final monthName = [
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.isLoading && logs.isEmpty
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Shimmer.fromColors(
                    baseColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF232323)
                        : const Color(0xFFE5E7EB),
                    highlightColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFF3F4F6),
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Text(
                    '$dayName, $monthName ${now.day}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Daily Intake\nLog',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Colors.black12,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$done/$total',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'Done',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Log All button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _logAllTaken,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Log All as Taken'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Log items
                  if (logs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.checklist_outlined,
                              size: 56,
                              color: AppColors.inactiveUpcoming.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No medications scheduled today',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...logs.map((log) {
                      final matches = medsProvider.medications
                          .where((m) => m.id == log.medicationId)
                          .toList(growable: false);
                      final med = matches.isEmpty ? null : matches.first;
                      final isTaken = log.status == 'taken';
                      final isMissed = log.status == 'missed';
                      final dotColor = isTaken
                          ? AppColors.primary
                          : isMissed
                          ? AppColors.missedAlert
                          : const Color(0xFFCBD5E1);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Timeline dot
                            Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isMissed
                                      ? Border(
                                          left: BorderSide(
                                            color: AppColors.missedAlert,
                                            width: 3,
                                          ),
                                        )
                                      : null,
                                  boxShadow: const [
                                    BoxShadow(
                                      blurRadius: 6,
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
                                        color:
                                            (isTaken
                                                    ? AppColors.primary
                                                    : isMissed
                                                    ? AppColors.missedAlert
                                                    : AppColors
                                                          .inactiveUpcoming)
                                                .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.medication_outlined,
                                        color: isTaken
                                            ? AppColors.primary
                                            : isMissed
                                            ? AppColors.missedAlert
                                            : AppColors.inactiveUpcoming,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med?.name ?? 'Medication',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            isMissed
                                                ? 'Missed • ${_fmtTime(log.scheduledTime)}'
                                                : '${med?.dosageStrength ?? ''}${med?.dosageUnit ?? ''} • ${_fmtTime(log.scheduledTime)}',
                                            style: TextStyle(
                                              color: isMissed
                                                  ? AppColors.missedAlert
                                                  : AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Action button
                                    if (log.status == 'upcoming')
                                      GestureDetector(
                                        onTap: () => context
                                            .read<IntakeLogProvider>()
                                            .markTaken(log),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.inactiveUpcoming,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 18,
                                            color: AppColors.inactiveUpcoming,
                                          ),
                                        ),
                                      )
                                    else if (log.status == 'taken')
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      GestureDetector(
                                        onTap: () => context
                                            .read<IntakeLogProvider>()
                                            .markTaken(log),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.missedAlert,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.refresh,
                                            size: 18,
                                            color: AppColors.missedAlert,
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
                    }),

                  const SizedBox(height: 16),

                  // Tip card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reminder Tip',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Taking your medications with water helps absorption. Keep it up!',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
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
