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
  final _controller = TextEditingController(text: 'Time to take your medication.');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Reminders')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Enable voice reminders', style: TextStyle(fontWeight: FontWeight.w900)),
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
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Test phrase',
                hintText: 'Time to take your...',
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
                    label: const Text('Speak'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => VoiceService.instance.stop(),
                    icon: const Icon(Icons.stop_circle_outlined, color: AppColors.missedAlert),
                    label: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

