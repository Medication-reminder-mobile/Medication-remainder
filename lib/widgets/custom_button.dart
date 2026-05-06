import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.fullWidth = true,
    this.semanticsLabel,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final bool fullWidth;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final child = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text);

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c),
              foregroundColor: c,
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(backgroundColor: c),
            child: child,
          );

    return Semantics(
      button: true,
      label: semanticsLabel ?? text,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        child: button,
      ),
    );
  }
}

