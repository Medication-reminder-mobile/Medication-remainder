import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../models/medication_model.dart';
import '../../providers/medication_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class MedsEditScreen extends StatefulWidget {
  const MedsEditScreen({super.key, required this.id});

  final int id;

  @override
  State<MedsEditScreen> createState() => _MedsEditScreenState();
}

class _MedsEditScreenState extends State<MedsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _strength = TextEditingController();
  final _unit = TextEditingController();
  final _times = TextEditingController();
  String _shape = 'capsule';
  String _color = '#00897B';
  String _frequency = 'daily';
  bool _voiceReminder = false;
  bool _init = false;

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _unit.dispose();
    _times.dispose();
    super.dispose();
  }

  void _populate(MedicationModel med) {
    _name.text = med.name;
    _strength.text = med.dosageStrength;
    _unit.text = med.dosageUnit;
    _times.text = med.scheduledTimes.join(',');
    _shape = med.pillShape;
    _color = med.pillColor;
    _frequency = med.frequency;
    _voiceReminder = med.tags.contains('voice_enabled');
    _init = true;
  }

  Future<void> _save(MedicationModel old) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final times = _times.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => RegExp(r'^\d{2}:\d{2}$').hasMatch(e))
        .toList(growable: false);

    final updated = old.copyWith(
      name: _name.text.trim(),
      dosageStrength: _strength.text.trim(),
      dosageUnit: _unit.text.trim(),
      frequency: _frequency,
      pillShape: _shape,
      pillColor: _color,
      scheduledTimes: times.isEmpty ? old.scheduledTimes : times,
      tags: _voiceReminder ? const ['voice_enabled'] : const ['text_only'],
    );

    await context.read<MedicationProvider>().updateMedication(updated);
    if (!mounted) return;
    final err = context.read<MedicationProvider>().errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    // FIX: use context.pop() (GoRouter) instead of Navigator.of(context).pop()
    // Mixing Navigator and GoRouter corrupts the route stack.
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();
    MedicationModel? med;
    for (final m in provider.medications) {
      if (m.id == widget.id) {
        med = m;
        break;
      }
    }

    if (med == null) {
      return Scaffold(
        appBar: AppBar(
          // FIX: back button present even on "not found" state
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Edit Medication'),
        ),
        body: const Center(child: Text('Medication not found.')),
      );
    }
    final item = med;
    if (!_init) _populate(item);

    return Scaffold(
      appBar: AppBar(
        // FIX: explicit back/close button so the user can cancel without saving
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          tooltip: 'Cancel',
        ),
        title: const Text('Edit Medication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                label: 'Medication name',
                prefixIcon: Icons.medication_outlined,
                controller: _name,
                validator: (v) =>
                    Validators.requiredField(v, label: 'Medication name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Strength',
                      prefixIcon: Icons.numbers_outlined,
                      controller: _strength,
                      validator: (v) =>
                          Validators.requiredField(v, label: 'Strength'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppTextField(
                      label: 'Unit',
                      prefixIcon: Icons.straighten_outlined,
                      controller: _unit,
                      validator: (v) =>
                          Validators.requiredField(v, label: 'Unit'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Scheduled times (HH:mm, comma separated)',
                prefixIcon: Icons.schedule_outlined,
                controller: _times,
                validator: (v) =>
                    Validators.requiredField(v, label: 'Scheduled times'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _frequency,
                      decoration: const InputDecoration(labelText: 'Frequency'),
                      items: const [
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text('Daily'),
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('Weekly'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _frequency = v ?? 'daily'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _shape,
                      decoration: const InputDecoration(
                        labelText: 'Pill shape',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'capsule',
                          child: Text('Capsule'),
                        ),
                        DropdownMenuItem(
                          value: 'round',
                          child: Text('Round'),
                        ),
                        DropdownMenuItem(
                          value: 'square',
                          child: Text('Square'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _shape = v ?? 'capsule'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Voice reminder'),
                subtitle: const Text('Speak medication name when enabled'),
                value: _voiceReminder,
                onChanged: (v) => setState(() => _voiceReminder = v),
              ),
              const SizedBox(height: 8),
              AppButton(
                text: 'Save Changes',
                isLoading: provider.isLoading,
                onPressed: provider.isLoading ? null : () => _save(item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}