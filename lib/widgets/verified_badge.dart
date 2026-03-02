import 'package:flutter/material.dart';
import '../config/theme.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showText;

  const VerifiedBadge({super.key, this.size = 16, this.showText = false});

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.greenLight,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: AppColors.green),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      );
    }

    return Icon(
      Icons.verified,
      size: size,
      color: AppColors.teal,
    );
  }
}

class LocalSathiIdBadge extends StatelessWidget {
  final String id;
  final double fontSize;

  const LocalSathiIdBadge({super.key, required this.id, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        id,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: AppColors.tealDark,
        ),
      ),
    );
  }
}

class SponsoredBadge extends StatelessWidget {
  const SponsoredBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: const Text(
        'SPONSORED',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
