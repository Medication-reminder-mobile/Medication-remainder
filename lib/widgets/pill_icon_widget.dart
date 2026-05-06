import 'package:flutter/material.dart';

class PillIcon extends StatelessWidget {
  const PillIcon({
    super.key,
    required this.shape,
    required this.colorHex,
    this.size = 48,
    this.semanticsLabel,
  });

  final String shape; // capsule|round|square
  final String colorHex;
  final double size;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = _parseHex(colorHex) ?? Theme.of(context).colorScheme.primary;
    final borderRadius = switch (shape) {
      'round' => BorderRadius.circular(size),
      'square' => BorderRadius.circular(10),
      _ => BorderRadius.circular(size / 2),
    };

    final w = shape == 'capsule' ? size * 1.4 : size;
    final h = size;

    return Semantics(
      label: semanticsLabel ?? 'Pill icon',
      image: true,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: borderRadius,
          boxShadow: const [
            BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Colors.black12),
          ],
        ),
      ),
    );
  }

  Color? _parseHex(String hex) {
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }
}

