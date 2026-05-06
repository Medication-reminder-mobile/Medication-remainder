import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../services/voice_service.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  bool _enabled = VoiceService.instance.isEnabled;
  final _controller = TextEditingController(text: 'Log 500mg Ibuprofen');
  bool _isListening = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Enable voice reminders',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (v) {
                      setState(() => _enabled = v);
                      VoiceService.instance.isEnabled = v;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(blurRadius: 10, offset: Offset(0, 2), color: Colors.black12),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isListening ? 'Listening...' : 'Tap to Listen',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isListening ? "I'm listening... Log medication..." : 'Press the mic and speak',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _WaveformBar(isListening: _isListening),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: !_enabled
                  ? null
                  : () async {
                      setState(() => _isListening = !_isListening);
                      if (!_isListening) await VoiceService.instance.stop();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: _isListening ? 110 : 96,
                height: _isListening ? 110 : 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _enabled ? AppColors.primary : AppColors.inactiveUpcoming,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 24,
                            spreadRadius: 8,
                          )
                        ]
                      : const [],
                ),
                child: const Icon(Icons.mic, size: 42, color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Try saying',
                hintText: 'Log 500mg Ibuprofen',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !_enabled
                        ? null
                        : () async {
                            await VoiceService.instance.speak(_controller.text.trim());
                          },
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Test Command'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setState(() => _isListening = false);
                      await VoiceService.instance.stop();
                    },
                    icon: const Icon(Icons.stop_circle_outlined, color: AppColors.missedAlert),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Hint: Try saying "Log 500mg Ibuprofen".',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformBar extends StatelessWidget {
  const _WaveformBar({required this.isListening});
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final bars = <double>[12, 18, 10, 24, 14, 20, 11, 16, 9, 15, 13, 19];
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: bars
            .map(
              (h) => AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 5,
                height: isListening ? h : 8,
                decoration: BoxDecoration(
                  color: isListening ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

