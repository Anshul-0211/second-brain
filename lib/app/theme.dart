import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System: "Aether Intelligence — The Cognitive Nebula"
/// Derived from Stitch MCP design tokens.

class AppTheme {
  // ─── Primary Colors ───
  static const Color primary = Color(0xFFBD9DFF);
  static const Color primaryDim = Color(0xFF8A4CFC);
  static const Color primaryContainer = Color(0xFFB28CFF);
  
  // ─── Secondary ───
  static const Color secondary = Color(0xFFA88CFB);
  static const Color secondaryContainer = Color(0xFF4F319C);
  
  // ─── Tertiary ───
  static const Color tertiary = Color(0xFFFF97B2);
  
  // ─── Surfaces ───
  static const Color background = Color(0xFF100C1B);
  static const Color surface = Color(0xFF100C1B);
  static const Color surfaceContainer = Color(0xFF1C1729);
  static const Color surfaceContainerHigh = Color(0xFF221C31);
  static const Color surfaceContainerHighest = Color(0xFF282238);
  static const Color surfaceContainerLow = Color(0xFF151121);
  static const Color surfaceBright = Color(0xFF2F2840);
  
  // ─── Text Colors ───
  static const Color onBackground = Color(0xFFEBE2F8);
  static const Color onSurface = Color(0xFFEBE2F8);
  static const Color onSurfaceVariant = Color(0xFFAFA8BD);
  static const Color onPrimary = Color(0xFF3C0089);
  
  // ─── Outline ───
  static const Color outline = Color(0xFF797286);
  static const Color outlineVariant = Color(0xFF4B4557);

  // ─── Error ───
  static const Color error = Color(0xFFFF6E84);
  
  // ─── Category Colors ───
  static const Map<String, Color> categoryColors = {
    'Tech': Color(0xFF6366F1),
    'Finance': Color(0xFF10B981),
    'Study': Color(0xFFF59E0B),
    'Personal': Color(0xFFEC4899),
    'Entertainment': Color(0xFF8B5CF6),
    'News': Color(0xFF3B82F6),
    'Health': Color(0xFF14B8A6),
    'Other': Color(0xFF6B7280),
  };

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDim, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0x0DB28CFF), // primaryContainer at 5%
      Color(0x331C1729), // surfaceContainer at 20%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme Data ───
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: onSurface,
        error: error,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryContainer.withValues(alpha: 0.4),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDim,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLow,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDim,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Glassmorphism card decoration
BoxDecoration glassDecoration({
  double opacity = 0.6,
  double borderRadius = 16,
  bool withGlow = false,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(borderRadius),
    gradient: AppTheme.cardGradient,
    border: Border.all(
      color: AppTheme.outlineVariant.withValues(alpha: 0.15),
      width: 1,
    ),
    boxShadow: withGlow
        ? [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.06),
              blurRadius: 40,
              offset: Offset.zero,
            ),
          ]
        : null,
  );
}
