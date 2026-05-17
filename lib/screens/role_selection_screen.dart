import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/utils/menu_helpers.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../providers/auth_provider.dart';
import '../services/db_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/med_illustration.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _role;
  bool _saving = false;

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    // New user (not yet registered) — go to auth to create account
    if (user == null || user.id == null) {
      context.go(AppRoutes.auth);
      return;
    }

    if (_role == null) return;
    setState(() => _saving = true);
    try {
      final updated = user.copyWith(role: _role);
      await DbService.instance.updateUser(updated);
      await SessionService().saveSession(updated);
      auth.setUser(updated);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // If user is already logged in (has id), they must pick a role.
    // If not logged in yet, "Continue to Setup" goes to auth.
    final needsRole = auth.currentUser?.id != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => showAppMenu(context),
          tooltip: 'Menu',
        ),
        title: const Text('MedRemind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none_outlined),
            onPressed: () => context.go('/voice'),
            tooltip: 'Voice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Illustration banner ──────────────────────────────
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRect(child: MedIllustration(variant: 0)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────────────
                  const Text(
                    'Welcome to\nMedRemind',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select your role to personalize your medical reminder experience and management tools.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Role cards ─────────────────────────────────
                  _RoleCard(
                    selected: _role == 'individual_user',
                    title: 'Individual User',
                    description:
                        'Manage your personal prescriptions, health logs, and daily medication schedule.',
                    icon: Icons.person_outline,
                    iconBg: AppColors.primary.withValues(alpha: 0.14),
                    iconColor: AppColors.primary,
                    onTap: () => setState(() => _role = 'individual_user'),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    selected: _role == 'individual_caregiver',
                    title: 'Individual Caregiver',
                    description:
                        'Support family members by tracking their medication adherence and health status.',
                    icon: Icons.group_outlined,
                    iconBg: const Color(0xFFFCE7F3),
                    iconColor: const Color(0xFFEC4899),
                    onTap: () => setState(() => _role = 'individual_caregiver'),
                  ),
                  const SizedBox(height: 12),
                  _RoleCard(
                    selected: _role == 'professional_caregiver',
                    title: 'Professional Caregiver',
                    description:
                        'Healthcare staff tools for managing multiple patients and medications.',
                    icon: Icons.medical_services_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    badge: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'System Secure',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    onTap: () =>
                        setState(() => _role = 'professional_caregiver'),
                  ),
                  const SizedBox(height: 20),

                  // ── Security banner ────────────────────────────
                  _SecurityBanner(),
                  const SizedBox(height: 20),

                  // ── CTA button ─────────────────────────────────
                  AppButton(
                    text: 'Continue to Setup',
                    isLoading: _saving,
                    onPressed:
                        (needsRole ? (_role == null || _saving) : _saving)
                        ? null
                        : _continue,
                    semanticsLabel: 'Continue to setup',
                  ),
                  const SizedBox(height: 12),

                  // ── Login link ─────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.auth),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Security banner ──────────────────────────────────────────────────────────

class _SecurityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background illustration (same scene, smaller)
          SizedBox(
            height: 110,
            width: double.infinity,
            child: MedIllustration(variant: 0),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),
          // Text
          const Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            right: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secured by industry-standard\nclinical encryption protocols.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role card ────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final String title;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 8,
                offset: Offset(0, 2),
                color: Colors.black12,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          badge!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
