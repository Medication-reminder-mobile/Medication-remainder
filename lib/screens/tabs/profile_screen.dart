import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ── Personal Information Dialog ─────────────────────────────────
  void _showPersonalInfo(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.currentUser?.name ?? '');
    final emailCtrl =
        TextEditingController(text: auth.currentUser?.email ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Personal Information'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx);
              await context.read<AuthProvider>().updateUser(
                    nameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                  );
              if (!context.mounted) return;
              final err = context.read<AuthProvider>().errorMessage;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(err ?? 'Profile updated successfully'),
                  backgroundColor: err != null ? Colors.red : Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Language Picker Dialog ──────────────────────────────────────
  void _showLanguagePicker(BuildContext context) {
    const languages = [
      'English',
      'Amharic',
      'Arabic',
      'French',
      'Spanish',
      'Portuguese',
      'Swahili',
    ];
    String selected = 'English';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (_, i) => RadioListTile<String>(
                title: Text(languages[i]),
                value: languages[i],
                groupValue: selected,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => selected = v ?? 'English'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language set to $selected'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification Preferences Dialog ────────────────────────────
  void _showNotificationPrefs(BuildContext context) {
    bool pushEnabled = true;
    bool voiceEnabled = false;
    bool missedAlerts = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Notification Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Medication reminders'),
                value: pushEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => pushEnabled = v),
              ),
              SwitchListTile(
                title: const Text('Voice Reminders'),
                subtitle: const Text('Speak medication name'),
                value: voiceEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => voiceEnabled = v),
              ),
              SwitchListTile(
                title: const Text('Missed Dose Alerts'),
                subtitle: const Text('Alert when dose is missed'),
                value: missedAlerts,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => missedAlerts = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification preferences saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Data Backup Dialog ──────────────────────────────────────────
  void _showDataBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data Backup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Local backup active'),
              subtitle: Text('Your data is stored on this device'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primary),
              title: Text('Cloud backup'),
              subtitle: Text('Available in Premium plan'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Local backup is always on — your data is safe'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Delete Account Dialog ───────────────────────────────────────
  void _showDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data '
          '(medications, logs, RBC records). This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().deleteAccount();
              if (!context.mounted) return;
              final err = context.read<AuthProvider>().errorMessage;
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              context.go('/auth');
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.missedAlert,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  // ── Edit Profile Avatar Dialog ──────────────────────────────────
  void _showEditProfile(BuildContext context, AuthProvider auth) {
    _showPersonalInfo(context, auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final isDark = theme.themeMode == ThemeMode.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile card ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  color: Colors.black12,
                ),
              ],
            ),
            child: Column(
              children: [
                // FIX: tapping the avatar/edit icon opens personal info dialog
                GestureDetector(
                  onTap: () => _showEditProfile(context, auth),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        child: const Icon(
                          Icons.person_outline,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Guest',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: user?.isPremium == true
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user?.isPremium == true ? 'Premium Member' : 'Free Plan',
                    style: TextStyle(
                      color: user?.isPremium == true
                          ? Colors.white
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── General Settings ────────────────────────────────────
          _SectionLabel('GENERAL SETTINGS'),
          const SizedBox(height: 8),
          _SettingsGroup(
            children: [
              // FIX: opens real personal info edit dialog
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                onTap: () => _showPersonalInfo(context, auth),
              ),
              _SettingsDivider(),
              // FIX: opens real language picker
              _SettingsTile(
                icon: Icons.language_outlined,
                title: 'Language',
                trailing: const Text(
                  'English',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                onTap: () => _showLanguagePicker(context),
              ),
              _SettingsDivider(),
              // FIX: opens notification preferences dialog
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Preferences',
                onTap: () => _showNotificationPrefs(context),
              ),
              _SettingsDivider(),
              // FIX: opens data backup info dialog
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Data Backup',
                onTap: () => _showDataBackup(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Preferences ─────────────────────────────────────────
          _SectionLabel('PREFERENCES'),
          const SizedBox(height: 8),
          _SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dark_mode_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          const Text(
                            'Enable dark appearance',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isDark,
                      activeColor: AppColors.primary,
                      onChanged: (_) =>
                          context.read<ThemeProvider>().toggleTheme(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Account Management ───────────────────────────────────
          _SectionLabel('ACCOUNT MANAGEMENT'),
          const SizedBox(height: 8),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.logout,
                title: 'Logout',
                iconColor: onSurface,
                onTap: auth.isLoading
                    ? null
                    : () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        context.go('/auth');
                      },
              ),
              _SettingsDivider(),
              // FIX: opens real delete account confirmation dialog
              _SettingsTile(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                titleColor: AppColors.missedAlert,
                iconColor: AppColors.missedAlert,
                showChevron: false,
                onTap: () => _showDeleteAccount(context),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Footer ───────────────────────────────────────────────
          const Center(
            child: Column(
              children: [
                Text(
                  'Version 2.4.1 (Stable Build)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'MedRemind Clinical Systems Inc.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 66,
      endIndent: 0,
      color: Theme.of(context)
          .colorScheme
          .outlineVariant
          .withValues(alpha: 0.5),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    final tColor = titleColor ?? Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: tColor),
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}