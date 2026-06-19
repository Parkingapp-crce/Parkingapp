import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'premium_card.dart';

/// Stitch-style metric tile — uppercase label-caps text, large data value,
/// optional icon in top-right. Matches the "Metric Tile" pattern from /new_ui.
class PremiumMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final bool isTrendPositive;
  final Color? valueColor;

  const PremiumMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.isTrendPositive = true,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontFamily: 'Inter',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: Theme.of(context).colorScheme.tertiary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  fontFamily: 'Inter',
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 6),
                Text(
                  trend!,
                  style: TextStyle(
                    color: isTrendPositive ? AppColors.tertiary : Theme.of(context).colorScheme.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
