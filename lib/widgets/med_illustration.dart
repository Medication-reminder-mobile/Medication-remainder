import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A Flutter-painted medical illustration scene.
/// [variant] 0 = pill bottle, 1 = calendar, 2 = care/people.
class MedIllustration extends StatelessWidget {
  const MedIllustration({super.key, required this.variant});
  final int variant;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScenePainter(variant: variant),
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Floating orbs (behind subject)
            ..._buildOrbs(),
            // Central subject
            Center(child: _buildSubject()),
          ],
        ),
      ),
    );
  }

  Widget _buildSubject() {
    switch (variant) {
      case 1:
        return const _CalendarSubject();
      case 2:
        return const _CareSubject();
      default:
        return const _PillBottleSubject();
    }
  }

  List<Widget> _buildOrbs() {
    // Use Align with fractional offsets — safe inside Stack without LayoutBuilder
    final configs = switch (variant) {
      1 => [
        _OrbConfig(ax: -0.76, ay: -0.84, size: 44, opacity: 0.55),
        _OrbConfig(ax: 0.76, ay: -0.70, size: 28, opacity: 0.40),
        _OrbConfig(ax: -0.84, ay: 0.64, size: 36, opacity: 0.45),
        _OrbConfig(ax: 0.72, ay: 0.80, size: 52, opacity: 0.35),
        _OrbConfig(ax: -0.90, ay: -0.30, size: 20, opacity: 0.50),
      ],
      2 => [
        _OrbConfig(ax: -0.84, ay: -0.88, size: 50, opacity: 0.45),
        _OrbConfig(ax: 0.88, ay: -0.60, size: 32, opacity: 0.50),
        _OrbConfig(ax: -0.76, ay: 0.76, size: 40, opacity: 0.40),
        _OrbConfig(ax: 0.80, ay: 0.84, size: 24, opacity: 0.55),
      ],
      _ => [
        _OrbConfig(ax: -0.80, ay: -0.88, size: 38, opacity: 0.55),
        _OrbConfig(ax: 0.84, ay: -0.64, size: 52, opacity: 0.40),
        _OrbConfig(ax: -0.92, ay: -0.24, size: 28, opacity: 0.50),
        _OrbConfig(ax: 0.88, ay: 0.60, size: 44, opacity: 0.45),
        _OrbConfig(ax: -0.68, ay: 0.84, size: 22, opacity: 0.60),
        _OrbConfig(ax: 0.64, ay: 0.10, size: 18, opacity: 0.35),
      ],
    };
    return configs.map((c) => _FloatingOrb(config: c)).toList();
  }
}

// ── Background painter ───────────────────────────────────────────────────────

class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.variant});
  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: switch (variant) {
          1 => const [Color(0xFF0D4F4A), Color(0xFF1A6B5E), Color(0xFF0A3D38)],
          2 => const [Color(0xFF0A3D4A), Color(0xFF1A5E6B), Color(0xFF083040)],
          _ => const [Color(0xFF0D4A47), Color(0xFF1A6B62), Color(0xFF083D3A)],
        },
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF2DD4BF).withValues(alpha: 0.15),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.5, size.height * 0.45),
              radius: size.width * 0.55,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.45),
      size.width * 0.55,
      glowPaint,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.82),
        width: size.width * 0.45,
        height: 18,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.variant != variant;
}

// ── Pill bottle ──────────────────────────────────────────────────────────────

class _PillBottleSubject extends StatelessWidget {
  const _PillBottleSubject();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C55).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 110,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C55).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 130,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C55).withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF2DD4BF).withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 30, 8, 8),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: List.generate(
                            14,
                            (i) => Container(
                              width: 18,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2DD4BF,
                                ).withValues(alpha: 0.75 - (i * 0.02)),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        width: 12,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: 72,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFB8956A),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                    bottom: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Calendar subject ─────────────────────────────────────────────────────────

class _CalendarSubject extends StatelessWidget {
  const _CalendarSubject();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2DD4BF).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'MAY 2026',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.count(
                crossAxisCount: 7,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                children: List.generate(21, (i) {
                  final day = i + 1;
                  final isToday = day == 6;
                  final isTaken = day < 6;
                  return Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.primary
                          : isTaken
                          ? const Color(0xFF2DD4BF).withValues(alpha: 0.25)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isToday ? Colors.white : const Color(0xFF94D4CC),
                        fontSize: 9,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Care subject ─────────────────────────────────────────────────────────────

class _CareSubject extends StatelessWidget {
  const _CareSubject();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        _PersonFigure(size: 80, color: Color(0xFF2DD4BF)),
        SizedBox(width: 12),
        _PersonFigure(size: 100, color: Color(0xFF14B8A6)),
        SizedBox(width: 12),
        _PersonFigure(size: 72, color: Color(0xFF5EEAD4)),
      ],
    );
  }
}

class _PersonFigure extends StatelessWidget {
  const _PersonFigure({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 0.38,
          height: size * 0.38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: size * 0.5,
          height: size * 0.55,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.7),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
              bottom: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(2, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Floating orb ─────────────────────────────────────────────────────────────

class _OrbConfig {
  const _OrbConfig({
    required this.ax,
    required this.ay,
    required this.size,
    required this.opacity,
  });

  /// Alignment x: -1.0 = left edge, 1.0 = right edge
  final double ax;

  /// Alignment y: -1.0 = top edge, 1.0 = bottom edge
  final double ay;
  final double size;
  final double opacity;
}

class _FloatingOrb extends StatelessWidget {
  const _FloatingOrb({required this.config});
  final _OrbConfig config;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(config.ax, config.ay),
      child: Container(
        width: config.size,
        height: config.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF7DD3C8).withValues(alpha: config.opacity),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
