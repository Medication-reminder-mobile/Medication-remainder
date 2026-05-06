import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/medication_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medication_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class MedsAddScreen extends StatefulWidget {
  const MedsAddScreen({super.key});

  @override
  State<MedsAddScreen> createState() => _MedsAddScreenState();
}

class _MedsAddScreenState extends State<MedsAddScreen> {
  int _step = 0; // 0=Info, 1=Schedule, 2=Alerts

  // Step 1 — Info
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _strength = TextEditingController();
  final _unit = TextEditingController(text: 'mg');
  String _shape = 'capsule';
  String _color = '#00897B';

  // Step 2 — Schedule
  String _frequency = 'daily';
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _voiceReminder = false;

  // Step 3 — Alerts
  final _refillCount = TextEditingController(text: '30');
  final _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _unit.dispose();
    _refillCount.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final med = MedicationModel(
      id: null,
      userId: userId,
      name: _name.text.trim(),
      pillShape: _shape,
      pillColor: _color,
      dosageStrength: _strength.text.trim(),
      dosageUnit: _unit.text.trim(),
      frequency: _frequency,
      scheduledTimes: _times.map(_fmtTime).toList(),
      status: 'active',
      refillCount: int.tryParse(_refillCount.text.trim()) ?? 30,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      tags: const [],
      createdAt: DateTime.now(),
    );

    await context.read<MedicationProvider>().addMedication(med);
    if (!mounted) return;
    final err = context.read<MedicationProvider>().errorMessage;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.go('/meds');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicationProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/meds'),
          tooltip: 'Close',
        ),
        title: const Text('Add Medication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fill in your medication details across 3 steps'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: List.generate(3, (i) {
                final labels = ['Info', 'Schedule', 'Alerts'];
                final active = i == _step;
                final done = i < _step;
                return Expanded(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.primary
                                  : active
                                  ? AppColors.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: done
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: active
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (i < 2)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 20),
                            color: i < _step
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(provider),
              ][_step],
            ),
          ),
          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _step < 2
                        ? ElevatedButton(
                            onPressed: () {
                              if (_step == 0) {
                                if (!(_formKey.currentState?.validate() ??
                                    false))
                                  return;
                              }
                              setState(() => _step++);
                            },
                            child: const Text('Next Step'),
                          )
                        : AppButton(
                            text: 'Save Medication',
                            isLoading: provider.isLoading,
                            onPressed: provider.isLoading ? null : _save,
                            semanticsLabel: 'Save medication',
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

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('MEDICATION NAME'),
          const SizedBox(height: 6),
          AppTextField(
            label: '',
            hint: 'e.g. Atorvastatin',
            prefixIcon: Icons.medication_outlined,
            controller: _name,
            validator: (v) =>
                Validators.requiredField(v, label: 'Medication name'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _label('PILL SHAPE & COLOR'),
          const SizedBox(height: 10),
          // Shape selector
          Row(
            children: [
              _ShapeOption(
                icon: Icons.medication_outlined,
                label: 'Capsule',
                value: 'capsule',
                selected: _shape == 'capsule',
                onTap: () => setState(() => _shape = 'capsule'),
              ),
              const SizedBox(width: 10),
              _ShapeOption(
                icon: Icons.circle_outlined,
                label: 'Round',
                value: 'round',
                selected: _shape == 'round',
                onTap: () => setState(() => _shape = 'round'),
              ),
              const SizedBox(width: 10),
              _ShapeOption(
                icon: Icons.crop_square_outlined,
                label: 'Square',
                value: 'square',
                selected: _shape == 'square',
                onTap: () => setState(() => _shape = 'square'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Color picker
          Row(
            children: [
              _ColorDot(
                hex: '#00897B',
                selected: _color == '#00897B',
                onTap: () => setState(() => _color = '#00897B'),
              ),
              const SizedBox(width: 10),
              _ColorDot(
                hex: '#EF4444',
                selected: _color == '#EF4444',
                onTap: () => setState(() => _color = '#EF4444'),
              ),
              const SizedBox(width: 10),
              _ColorDot(
                hex: '#92400E',
                selected: _color == '#92400E',
                onTap: () => setState(() => _color = '#92400E'),
              ),
              const SizedBox(width: 10),
              _ColorDot(
                hex: '#3B82F6',
                selected: _color == '#3B82F6',
                onTap: () => setState(() => _color = '#3B82F6'),
              ),
              const SizedBox(width: 10),
              _ColorDot(
                hex: '#F59E0B',
                selected: _color == '#F59E0B',
                onTap: () => setState(() => _color = '#F59E0B'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('DOSAGE STRENGTH'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  label: '',
                  hint: '20',
                  prefixIcon: Icons.numbers_outlined,
                  controller: _strength,
                  validator: (v) =>
                      Validators.requiredField(v, label: 'Strength'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppTextField(
                  label: '',
                  hint: 'mg',
                  prefixIcon: Icons.straighten_outlined,
                  controller: _unit,
                  validator: (v) => Validators.requiredField(v, label: 'Unit'),
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('FREQUENCY'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
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
              _FreqOption(
                label: 'Daily',
                icon: Icons.calendar_today_outlined,
                value: 'daily',
                selected: _frequency == 'daily',
                onTap: () => setState(() => _frequency = 'daily'),
              ),
              _FreqOption(
                label: 'Weekly',
                icon: Icons.view_week_outlined,
                value: 'weekly',
                selected: _frequency == 'weekly',
                onTap: () => setState(() => _frequency = 'weekly'),
              ),
              _FreqOption(
                label: 'Custom',
                icon: Icons.tune_outlined,
                value: 'custom',
                selected: _frequency == 'custom',
                onTap: () => setState(() => _frequency = 'custom'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _label('SCHEDULED TIMES'),
        const SizedBox(height: 10),
        ..._times.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
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
                  const Icon(Icons.schedule_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    _fmtTime(_times[e.key]),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _pickTime(e.key),
                    child: const Text('Change'),
                  ),
                  if (_times.length > 1)
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: AppColors.missedAlert,
                      ),
                      onPressed: () => setState(() => _times.removeAt(e.key)),
                    ),
                ],
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () =>
              setState(() => _times.add(const TimeOfDay(hour: 20, minute: 0))),
          icon: const Icon(Icons.add),
          label: const Text('Add another time'),
        ),
        const SizedBox(height: 20),
        // Voice reminder toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
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
                  color: AppColors.missedAlert.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volume_up_outlined,
                  color: AppColors.missedAlert,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Reminder',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Assistant will speak the name',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _voiceReminder,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _voiceReminder = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(MedicationProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('REFILL COUNT'),
        const SizedBox(height: 6),
        AppTextField(
          label: '',
          hint: '30',
          prefixIcon: Icons.inventory_2_outlined,
          controller: _refillCount,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _label('NOTES (OPTIONAL)'),
        const SizedBox(height: 6),
        AppTextField(
          label: '',
          hint: 'e.g. Take with food',
          prefixIcon: Icons.notes_outlined,
          controller: _notes,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 24),
        // Summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Summary',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              _summaryRow('Name', _name.text.isEmpty ? '—' : _name.text),
              _summaryRow('Dosage', '${_strength.text}${_unit.text}'),
              _summaryRow('Frequency', _frequency),
              _summaryRow('Times', _times.map(_fmtTime).join(', ')),
              _summaryRow('Shape', _shape),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.8,
    ),
  );

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    ),
  );
}

class _ShapeOption extends StatelessWidget {
  const _ShapeOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreqOption extends StatelessWidget {
  const _FreqOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.hex,
    required this.selected,
    required this.onTap,
  });
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Color(int.parse('FF${hex.substring(1)}', radix: 16));
    return Semantics(
      button: true,
      label: 'Select color $hex',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
