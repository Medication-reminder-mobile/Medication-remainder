import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _login = true;
  bool _obscure = true;
  bool _remember = true;

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _confirm = TextEditingController();

  PasswordStrength _strength = PasswordStrength.none;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    if (_login) {
      await auth.login(_email.text, _password.text, rememberMe: _remember);
    } else {
      await auth.register(
        _name.text,
        _email.text,
        _password.text,
        '',
      ); // role set on role-select
    }

    if (!mounted) return;
    if (auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
      return;
    }

    final role = auth.currentUser?.role ?? '';
    if (role.isEmpty) {
      context.go(AppRoutes.roleSelect);
    } else {
      // Role-based redirect: router's /home builder handles patient vs caregiver
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.themeMode == ThemeMode.dark;

    final toggleBg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF1F5F9);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: toggleBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabPill(
                        text: 'Login',
                        selected: _login,
                        onTap: () => setState(() => _login = true),
                      ),
                    ),
                    Expanded(
                      child: _TabPill(
                        text: 'Register',
                        selected: !_login,
                        onTap: () => setState(() => _login = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.medication_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'MedRemind',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your health journey, organized.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Google',
                              isOutlined: true,
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Social login not configured',
                                      ),
                                    ),
                                  ),
                              semanticsLabel: 'Continue with Google',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppButton(
                              text: 'Facebook',
                              isOutlined: true,
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Social login not configured',
                                      ),
                                    ),
                                  ),
                              semanticsLabel: 'Continue with Facebook',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          SizedBox(width: 12),
                          Text(
                            'OR CONTINUE WITH EMAIL',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_login) ...[
                        AppTextField(
                          label: 'Full Name',
                          hint: 'Sara Doe',
                          prefixIcon: Icons.person_outline,
                          controller: _name,
                          validator: (v) =>
                              Validators.requiredField(v, label: 'Full name'),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ],
                      AppTextField(
                        label: 'Email Address',
                        hint: 'name@example.com',
                        prefixIcon: Icons.mail_outline,
                        controller: _email,
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Password',
                        prefixIcon: Icons.lock_outline,
                        controller: _password,
                        obscureText: _obscure,
                        validator: Validators.password,
                        onChanged: (v) =>
                            setState(() => _strength = Validators.strength(v)),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                        ),
                        textInputAction: _login
                            ? TextInputAction.done
                            : TextInputAction.next,
                      ),
                      const SizedBox(height: 10),
                      _PasswordStrengthBar(strength: _strength),
                      const SizedBox(height: 10),
                      if (!_login) ...[
                        AppTextField(
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_outline,
                          controller: _confirm,
                          obscureText: true,
                          validator: (v) =>
                              Validators.confirmPassword(_password.text, v),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (_login)
                        Row(
                          children: [
                            Semantics(
                              label: 'Remember me',
                              child: Checkbox(
                                value: _remember,
                                onChanged: (v) =>
                                    setState(() => _remember = v ?? true),
                              ),
                            ),
                            const Text('Remember me'),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password reset not configured',
                                      ),
                                    ),
                                  ),
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                      AppButton(
                        text: _login
                            ? 'Sign In to MedRemind'
                            : 'Create Account',
                        isLoading: auth.isLoading,
                        onPressed: auth.isLoading ? null : _submit,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "By continuing, you agree to MedRemind's Terms of Service and Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Support not configured'),
                              ),
                            ),
                        child: const Text('Need help with your account?'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final level = strength.index; // 0..4
    Color segColor(int i) {
      if (i > level - 1) return Theme.of(context).colorScheme.outlineVariant;
      return switch (level) {
        1 => AppColors.missedAlert,
        2 => const Color(0xFFF97316),
        3 => AppColors.warningRefill,
        _ => AppColors.primary,
      };
    }

    final label = switch (strength) {
      PasswordStrength.weak => 'Weak',
      PasswordStrength.moderate => 'Moderate',
      PasswordStrength.strong => 'Strong',
      PasswordStrength.veryStrong => 'Very Strong',
      _ => '',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                decoration: BoxDecoration(
                  color: segColor(i + 1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.isEmpty ? '' : 'Strength: $label',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
