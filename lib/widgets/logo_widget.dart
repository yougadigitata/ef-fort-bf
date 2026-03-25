import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LogoWidget extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showBackground;

  const LogoWidget({
    super.key,
    this.size = 120,
    this.borderRadius = 20,
    this.showBackground = true,
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
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
