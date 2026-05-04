import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// After auth, user picks how they use the app — extend with permissions later.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _busy = false;
  String? _error;
  String _selectedLanguage = 'English';
  String? _selectedRole;

  Future<void> _choose(String role) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await AuthService.instance.setRole(role);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/profile');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not save role.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = AuthService.instance.currentUser?.name ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F7),
      appBar: AppBar(
        title: const Text(
          'MedRemember',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A7776),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                'Welcome',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF0A7776),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Let's set up your personalized experience, $name.",
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Choose Language',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _LanguageCard(
                      title: 'English',
                      isSelected: _selectedLanguage == 'English',
                      onTap: _busy
                          ? null
                          : () => setState(() => _selectedLanguage = 'English'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LanguageCard(
                      title: 'Amharic',
                      isSelected: _selectedLanguage == 'Amharic',
                      onTap: _busy
                          ? null
                          : () => setState(() => _selectedLanguage = 'Amharic'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Who are you?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      title: "I'm taking medication",
                      subtitle: 'Personal medication tracking',
                      icon: Icons.person_rounded,
                      selected: _selectedRole == UserModel.roleUser,
                      enabled: !_busy,
                      onTap: () => setState(() => _selectedRole = UserModel.roleUser),
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      title: 'Individual Caregiver',
                      subtitle: 'Help one family member',
                      icon: Icons.family_restroom_rounded,
                      selected: _selectedRole == UserModel.roleCaregiver,
                      enabled: !_busy,
                      onTap: () => setState(() => _selectedRole = UserModel.roleCaregiver),
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      title: 'Professional Caregiver',
                      subtitle: 'Manage multiple patients',
                      icon: Icons.medical_services_outlined,
                      selected: _selectedRole == UserModel.roleCaregiver,
                      enabled: !_busy,
                      onTap: () => setState(() => _selectedRole = UserModel.roleCaregiver),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _busy || _selectedRole == null
                    ? null
                    : () => _choose(_selectedRole!),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(_busy ? 'Saving...' : 'Continue'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFF0A7776),
                ),
              ),
              const SizedBox(height: 10),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _error!,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A7776) : const Color(0xFFD6DDDD),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF0A7776) : const Color(0xFF1E2727),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSelected ? 'Active' : 'Select',
                style: const TextStyle(fontSize: 18, color: Color(0xFF6C7878)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.selected,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F0EE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(icon, color: const Color(0xFF0A7776), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                color: selected ? const Color(0xFF0A7776) : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
