import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/medication_model.dart';
import '../../providers/medication_provider.dart';
import '../../widgets/pill_icon_widget.dart';

class CaregiverPatientMedsScreen extends StatelessWidget {
  const CaregiverPatientMedsScreen({super.key, required this.patientId});

  final int patientId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();
    final meds = provider.medications.where((m) => m.userId == patientId).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Meds')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: meds.isEmpty
            ? const Center(child: Text('No medications loaded for this patient.'))
            : ListView.separated(
                itemCount: meds.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _Tile(med: meds[i]),
              ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.med});
  final MedicationModel med;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12)],
      ),
      child: Row(
        children: [
          PillIcon(shape: med.pillShape, colorHex: med.pillColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('${med.dosageStrength}${med.dosageUnit}', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (med.status == 'paused' ? AppColors.inactiveUpcoming : AppColors.primary).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              med.status == 'paused' ? 'Paused' : 'Active',
              style: TextStyle(
                color: med.status == 'paused' ? AppColors.inactiveUpcoming : AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          )
        ],
      ),
    );
  }
}

