import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaraColors {
  // Brand primaries
  static const green = Color(0xFF00B96B);
  static const greenDark = Color(0xFF007A46);
  static const greenLight = Color(0xFFCCF5E4);
  static const navy = Color(0xFF0A1628);
  static const navyMid = Color(0xFF1B3A8A);
  static const navyAccent = Color(0xFF2563EB);

  // Vibrant accents
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFEF3C7);
  static const violet = Color(0xFF7C3AED);
  static const violetLight = Color(0xFFEDE9FE);
  static const rose = Color(0xFFE11D48);
  static const roseLight = Color(0xFFFFE4E6);

  // Surfaces
  static const surface = Color(0xFFF0F4FF);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const lightBlue = Color(0xFFE8F0FF);

  // Text
  static const textPrimary = Color(0xFF0A1628);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  // Gradient presets
  static const gradientNavy = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF1B3A8A), Color(0xFF2563EB)],
  );

  static const gradientGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B96B), Color(0xFF007A46)],
  );

  static const gradientAmber = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
  );

  static const gradientViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
  );
}

class MaraShadows {
  static List<BoxShadow> soft(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF0A1628).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF0A1628).withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevated = [
    BoxShadow(
      color: const Color(0xFF0A1628).withValues(alpha: 0.18),
      blurRadius: 48,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: const Color(0xFF0A1628).withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

class MaraTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MaraColors.navyMid,
        primary: MaraColors.navyMid,
        secondary: MaraColors.green,
        surface: MaraColors.surface,
      ),
      scaffoldBackgroundColor: MaraColors.surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: MaraColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MaraColors.navyMid,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.inter(color: MaraColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MaraColors.navyAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
