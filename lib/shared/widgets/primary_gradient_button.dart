import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/theme/app_colors.dart';

class PrimaryGradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;

  const PrimaryGradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 55,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : AppColors.primaryGradient,
        color: isDisabled ? cs.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled ? [] : AppColors.primaryButtonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isDisabled ? cs.onSurfaceVariant : Colors.white,
                    size: fontSize + 2,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: isDisabled ? cs.onSurfaceVariant : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryGradientButtonLoading extends StatelessWidget {
  final double height;

  const PrimaryGradientButtonLoading({super.key, this.height = 55});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.primaryButtonShadow,
      ),
      child: const Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
      ),
    );
  }
}
