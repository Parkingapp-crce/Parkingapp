import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.gradient,
    this.borderRadius = 16,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? Theme.of(context).colorScheme.surfaceContainerHighest) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(color: Theme.of(context).colorScheme.outlineVariant, width: 1.0),
      boxShadow: boxShadow,
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Ink(
              decoration: decoration,
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }
}
