import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Widget logo EF-FORT.BF — v2.0 ombres améliorées
class LogoWidget extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showBackground;
  final bool animate;

  const LogoWidget({
    super.key,
    this.size = 120,
    this.borderRadius = 20,
    this.showBackground = true,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showBackground
          ? BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      padding: showBackground ? const EdgeInsets.all(8) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 4),
        child: Image.asset(
          'assets/images/logo_effort.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
