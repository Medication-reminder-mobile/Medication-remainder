import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../widgets/med_illustration.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardData(
      title: 'Never miss a dose',
      subtitle:
          'Stay on top of your health with personalized medication reminders.',
      illustrationVariant: 0,
    ),
    _OnboardData(
      title: 'Stay on schedule',
      subtitle: 'Plan your day with a clear timeline and quick logging.',
      illustrationVariant: 1,
    ),
    _OnboardData(
      title: 'Care for your loved ones',
      subtitle: 'Support family members by monitoring adherence and alerts.',
      illustrationVariant: 2,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    context.go(AppRoutes.roleSelect);
  }

  Future<void> _next() async {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      if (!mounted) return;
      context.go(AppRoutes.roleSelect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(),
      child: Scaffold(
        backgroundColor: const Color(0xFFEEF4F4),
        body: SafeArea(
          child: Column(
            children: [
              // ── Page content ──────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, i) => _OnboardPage(data: _pages[i]),
                ),
              ),

              // ── Dot indicator ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: _pages.length,
                  effect: const WormEffect(
                    dotHeight: 8,
                    dotWidth: 24,
                    radius: 8,
                    activeDotColor: AppColors.primary,
                    dotColor: Color(0xFFCBD5E1),
                  ),
                ),
              ),

              // ── Navigation row ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Skip onboarding',
                      child: TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: _index == _pages.length - 1
                          ? 'Get started'
                          : 'Next page',
                      child: GestureDetector(
                        onTap: _next,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
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

// ── Data model ───────────────────────────────────────────────────────────────

class _OnboardData {
  const _OnboardData({
    required this.title,
    required this.subtitle,
    required this.illustrationVariant,
  });
  final String title;
  final String subtitle;
  final int illustrationVariant;
}

// ── Page layout ──────────────────────────────────────────────────────────────

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.data});
  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Illustration card ──────────────────────────────────
          Expanded(
            flex: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: MedIllustration(variant: data.illustrationVariant),
            ),
          ),
          const SizedBox(height: 28),

          // ── Title ─────────────────────────────────────────────
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),

          // ── Subtitle ──────────────────────────────────────────
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
