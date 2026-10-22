import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MedEase brand tokens — kept in sync with the web app's CSS variables
/// so the mobile app feels like the same product, not a reskin.
class MedEaseColors {
  MedEaseColors._();

  // Core brand
  static const Color primary = Color(0xFF2F6F63); // clinical teal-green
  static const Color primaryDark = Color(0xFF1F4E45);
  static const Color primaryLight = Color(0xFFE4F2EE);

  // Accent (used sparingly — payments, alerts, badges)
  static const Color accent = Color(0xFFDD8A3C); // warm amber, "attention" color
  static const Color danger = Color(0xFFC0453B);
  static const Color success = Color(0xFF2E9B5A);
  static const Color warning = Color(0xFFDD8A3C);
  static const Color info = Color(0xFF3B7DC0);

  // Neutrals
  static const Color ink = Color(0xFF1B2320);
  static const Color inkMuted = Color(0xFF5C6B66);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF6F8F7);
  static const Color border = Color(0xFFE0E7E4);

  // Role accents — used for badges / headers so role context is always visible
  static const Color patientRole = Color(0xFF2F6F63);
  static const Color doctorRole = Color(0xFF3B7DC0);
  static const Color adminRole = Color(0xFF6B4FA0);
}

class MedEaseTheme {
  MedEaseTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MedEaseColors.primary,
        primary: MedEaseColors.primary,
        secondary: MedEaseColors.accent,
        error: MedEaseColors.danger,
        surface: MedEaseColors.surface,
      ),
      scaffoldBackgroundColor: MedEaseColors.background,
      fontFamily: GoogleFonts.dmSans().fontFamily,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 30,
          color: MedEaseColors.ink,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 24,
          color: MedEaseColors.ink,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MedEaseColors.ink,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: MedEaseColors.ink,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          color: MedEaseColors.inkMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: MedEaseColors.surface,
        foregroundColor: MedEaseColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          color: MedEaseColors.ink,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: MedEaseColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MedEaseColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MedEaseColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedEaseColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedEaseColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MedEaseColors.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MedEaseColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MedEaseColors.primary,
          side: const BorderSide(color: MedEaseColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: MedEaseColors.primaryLight,
        labelStyle: const TextStyle(color: MedEaseColors.primaryDark, fontSize: 12),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(color: MedEaseColors.border, thickness: 1),
    );
  }

  static Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return MedEaseColors.doctorRole;
      case 'admin':
      case 'superadmin':
        return MedEaseColors.adminRole;
      default:
        return MedEaseColors.patientRole;
    }
  }
}
