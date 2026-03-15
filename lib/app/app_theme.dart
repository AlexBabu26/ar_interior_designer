import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color parchment = Color(0xFFE6E2E1);
  static const Color parchmentHighlight = Color(0xFFF4F0EC);
  static const Color mutedClay = Color(0xFFC3C0BE);
  static const Color sandyBeige = Color(0xFF9B8A71);
  static const Color deepUmber = Color(0xFF5F5B57);
  static const Color burntSienna = Color(0xFF9F623B);
  static const Color richCharcoal = Color(0xFF050404);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: richCharcoal,
        onPrimary: parchmentHighlight,
        secondary: burntSienna,
        onSecondary: parchmentHighlight,
        error: Color(0xFF9B2C2C),
        onError: Colors.white,
        surface: parchmentHighlight,
        onSurface: richCharcoal,
      ),
      scaffoldBackgroundColor: parchment,
      canvasColor: parchment,
    );

    final bodyTextTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.6,
        color: richCharcoal,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.6,
        color: deepUmber,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    final displayTextTheme =
        GoogleFonts.cormorantGaramondTextTheme(bodyTextTheme).copyWith(
          displayLarge: GoogleFonts.cormorantGaramond(
            fontSize: 56,
            height: 1,
            fontWeight: FontWeight.w600,
            color: richCharcoal,
          ),
          displayMedium: GoogleFonts.cormorantGaramond(
            fontSize: 44,
            height: 1.05,
            fontWeight: FontWeight.w600,
            color: richCharcoal,
          ),
          headlineLarge: GoogleFonts.cormorantGaramond(
            fontSize: 38,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: richCharcoal,
          ),
          headlineMedium: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: richCharcoal,
          ),
          titleLarge: GoogleFonts.cormorantGaramond(
            fontSize: 26,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: richCharcoal,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: richCharcoal,
          ),
          titleSmall: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: deepUmber,
          ),
          labelLarge: bodyTextTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: richCharcoal,
          ),
          labelSmall: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: deepUmber,
          ),
        );

    return base.copyWith(
      textTheme: displayTextTheme,
      dividerColor: mutedClay.withValues(alpha: 0.55),
      appBarTheme: AppBarTheme(
        backgroundColor: parchment,
        foregroundColor: richCharcoal,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: richCharcoal,
        ),
      ),
      cardTheme: CardThemeData(
        color: parchmentHighlight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: mutedClay.withValues(alpha: 0.45)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: parchmentHighlight,
        selectedColor: richCharcoal,
        secondarySelectedColor: richCharcoal,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: richCharcoal,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: parchmentHighlight,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: mutedClay.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: richCharcoal,
          foregroundColor: parchmentHighlight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: bodyTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: richCharcoal,
          side: BorderSide(color: mutedClay.withValues(alpha: 0.8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: bodyTextTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: parchmentHighlight,
          foregroundColor: richCharcoal,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          side: BorderSide(color: mutedClay.withValues(alpha: 0.65)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: parchmentHighlight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: mutedClay.withValues(alpha: 0.45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: mutedClay.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: burntSienna, width: 1.2),
        ),
        labelStyle: GoogleFonts.inter(color: deepUmber),
        helperStyle: GoogleFonts.inter(color: deepUmber),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: richCharcoal,
        contentTextStyle: GoogleFonts.inter(color: parchmentHighlight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: DividerThemeData(
        color: mutedClay.withValues(alpha: 0.55),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: richCharcoal),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFF1ECE7),
        onPrimary: richCharcoal,
        secondary: Color(0xFFD29A73),
        onSecondary: richCharcoal,
        error: Color(0xFFE7A5A5),
        onError: richCharcoal,
        surface: Color(0xFF191715),
        onSurface: Color(0xFFF1ECE7),
      ),
      scaffoldBackgroundColor: const Color(0xFF11100F),
      canvasColor: const Color(0xFF11100F),
    );

    final bodyTextTheme = GoogleFonts.interTextTheme(base.textTheme);
    final displayTextTheme =
        GoogleFonts.cormorantGaramondTextTheme(bodyTextTheme).copyWith(
          labelLarge: bodyTextTheme.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: const Color(0xFFF1ECE7),
          ),
          labelSmall: bodyTextTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: const Color(0xFFD6CEC6),
          ),
        );

    return base.copyWith(
      textTheme: displayTextTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF11100F),
        foregroundColor: Color(0xFFF1ECE7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF191715),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF1ECE7),
          foregroundColor: richCharcoal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: bodyTextTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF1ECE7),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: bodyTextTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF191715),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFD29A73)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFFF1ECE7),
        contentTextStyle: GoogleFonts.inter(color: richCharcoal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
