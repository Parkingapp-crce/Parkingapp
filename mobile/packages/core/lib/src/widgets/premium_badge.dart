import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumBadge extends StatelessWidget {
  final String label;
  final String? status;

  const PremiumBadge({
    super.key,
    required this.label,
    this.status,
  });

  Color _resolveColor(String statusStr) {
    final lower = statusStr.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (lower.contains('active') ||
        lower.contains('available') ||
        lower.contains('approved') ||
        lower.contains('success') ||
        lower.contains('completed')) {
      return AppColors.success;
    }
    if (lower.contains('pending') ||
        lower.contains('reserved') ||
        lower.contains('warning') ||
        lower.contains('waiting')) {
      return AppColors.warning;
    }
    if (lower.contains('error') ||
        lower.contains('cancelled') ||
        lower.contains('expired') ||
        lower.contains('no show') ||
        lower.contains('rejected') ||
        lower.contains('occupied')) {
      return const Color(0xFFEF4444);
    }
    if (lower.contains('blocked') || lower.contains('disabled')) {
      return AppColors.slotBlocked;
    }
    // Default blue-grey primary brand color
    return const Color(0xFF3B82F6);
  }

  @override
  Widget build(BuildContext context) {
    final activeStatus = status ?? label;
    final color = _resolveColor(activeStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.0,
        ),
      ),
      child: Text(
        label.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
