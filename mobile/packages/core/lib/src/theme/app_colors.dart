import 'package:flutter/material.dart';

/// ParkEase design tokens — matching the landing page purple/white theme.
/// Light: white background, indigo/violet primary, slate text.
/// Dark: deep slate background, bright indigo/lilac primary, pale text.
class AppColors {
  AppColors._();

  // ── Primary Brand ────────────────────────────────────────────────────────────
  /// Indigo-600 — primary CTA, buttons, links
  static const primary = Color(0xFF4F46E5);
  /// Violet-700 — gradient end, active states
  static const primaryDark = Color(0xFF7C3AED);
  /// Lilac — muted tinted text on dark surfaces
  static const primaryLight = Color(0xFFC084FC);
  /// Indigo container fill for chips/badges
  static const primaryContainer = Color(0xFFEEF2FF);

  // ── Secondary / Cyan Accent ──────────────────────────────────────────────────
  static const secondary = Color(0xFF06B6D4);     // cyan-500
  static const secondaryLight = Color(0xFF67E8F9);
  static const tertiary = primaryDark;

  // ── Status ───────────────────────────────────────────────────────────────────
  static const success = Color(0xFF10B981);        // emerald-500
  static const successBg = Color(0xFFD1FAE5);
  static const warning = Color(0xFFF59E0B);        // amber-500
  static const warningBg = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);          // red-500
  static const errorBg = Color(0xFFFEE2E2);
  static const errorContainer = Color(0xFF93000A);

  // ── Slot States ──────────────────────────────────────────────────────────────
  static const slotAvailable = Color(0xFF10B981);
  static const slotReserved = Color(0xFFF59E0B);
  static const slotOccupied = Color(0xFFEF4444);
  static const slotBlocked = Color(0xFF94A3B8);

  // ── Light Mode Surfaces ───────────────────────────────────────────────────────
  static const backgroundLight = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF8FAFC);       // slate-50
  static const surfaceContainerLowestLight = Color(0xFFF1F5F9);  // slate-100
  static const surfaceContainerLowLight = Color(0xFFE2E8F0);     // slate-200
  static const surfaceContainerLight = Color(0xFFCBD5E1);        // slate-300
  static const surfaceVariantLight = Color(0xFFF1F5F9);          // slate-100
  static const dividerLight = Color(0xFFE2E8F0);                 // slate-200
  static const outlineLight = Color(0xFFCBD5E1);                 // slate-300

  // ── Dark Mode Surfaces ────────────────────────────────────────────────────────
  static const backgroundDark = Color(0xFF0F172A);     // slate-900
  static const surfaceDark = Color(0xFF1E293B);         // slate-800
  static const surfaceContainerLowestDark = Color(0xFF0F172A);
  static const surfaceContainerLowDark = Color(0xFF1E293B);
  static const surfaceContainerDark = Color(0xFF334155); // slate-700
  static const surfaceVariantDark = Color(0xFF1E293B);
  static const dividerDark = Color(0xFF334155);
  static const outlineDark = Color(0xFF475569);

  // ── Light Mode Text ───────────────────────────────────────────────────────────
  static const textPrimaryLight = Color(0xFF0F172A);    // slate-900
  static const textSecondaryLight = Color(0xFF475569);  // slate-600
  static const textDisabledLight = Color(0xFF94A3B8);   // slate-400

  // ── Dark Mode Text ────────────────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFF1F5F9);     // slate-100
  static const textSecondaryDark = Color(0xFF94A3B8);   // slate-400
  static const textDisabledDark = Color(0xFF64748B);    // slate-500

  // ── Convenience getters (theme-aware) ─────────────────────────────────────────
  /// Call with [context] to get the correct color for the current brightness.
  static Color getBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? backgroundDark : backgroundLight;
  static Color getSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surfaceDark : surfaceLight;
  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
  static Color getDivider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dividerDark : dividerLight;

  // ── Static shorthands (for widgets that can't access context) ─────────────────
  // These map to the LIGHT mode values by default (used in static const contexts).
  static const background = backgroundLight;
  static const surface = surfaceLight;
  static const surfaceContainerLowest = surfaceContainerLowestLight;
  static const surfaceContainerLow = surfaceContainerLowLight;
  static const surfaceContainer = surfaceContainerLight;
  static const surfaceContainerHigh = Color(0xFFE2E8F0);
  static const surfaceContainerHighest = Color(0xFFCBD5E1);
  static const surfaceVariant = surfaceVariantLight;
  static const surfaceBright = Color(0xFFFFFFFF);
  static const textPrimary = textPrimaryLight;
  static const textSecondary = textSecondaryLight;
  static const textDisabled = textDisabledLight;
  static const divider = dividerLight;
  static const outline = outlineLight;

  // ── Brand Gradient ─────────────────────────────────────────────────────────────
  static const gradPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFFC084FC)],
    stops: [0.0, 0.5, 1.0],
  );

  static const gradAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  );
}
