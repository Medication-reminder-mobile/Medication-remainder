import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/medication_model.dart';
import '../../providers/medication_provider.dart';
import '../../widgets/pill_icon_widget.dart';

class MedsDetailScreen extends StatelessWidget {
  const MedsDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final meds = context.watch<MedicationProvider>().medications;
    MedicationModel? med;
    for (final m in meds) {
      if (m.id == id) {
        med = m;
        break;
      }
    }
    if (med == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medication')),
        body: const Center(child: Text('Medication not found.')),
      );
    }
    final item = med;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            onPressed: () => context.go('/meds/edit/${item.id ?? 0}'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit medication',
          ),
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete medication?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.missedAlert))),
                  ],
                ),
              );
              if (!context.mounted) return;
              if (ok != true) return;
              await context.read<MedicationProvider>().deleteMedication(id);
              if (!context.mounted) return;
              final err = context.read<MedicationProvider>().errorMessage;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                return;
              }
              context.pop();
            },
            icon: const Icon(Icons.delete_outline, color: AppColors.missedAlert),
            tooltip: 'Delete medication',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12)],
              ),
              child: Row(
                children: [
                  PillIcon(shape: item.pillShape, colorHex: item.pillColor, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('${item.dosageStrength}${item.dosageUnit} • ${item.frequency}', style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text('Times: ${item.scheduledTimes.join(', ')}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Pause reminders when off'),
              value: item.status != 'paused',
              onChanged: (v) => context.read<MedicationProvider>().toggleStatus(id, v ? 'active' : 'paused'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Refill count'),
              subtitle: Text('${item.refillCount} doses remaining'),
            ),
          ],
        ),
      ),
    );
  }
}

