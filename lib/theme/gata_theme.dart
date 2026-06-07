import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GataColors {
  // ── Accent (brand identity, used on gradients & active elements) ──
  static const rose = Color(0xFFE8A0B4);
  static const roseLight = Color(0xFFF5D0DE);
  static const roseDark = Color(0xFFC2607A);
  static const lavender = Color(0xFFB8A0D4);
  static const lavenderLight = Color(0xFFE8DCFA);
  static const mauve = Color(0xFF8B6B8F);

  // ── Dark surface system ──
  static const bg = Color(0xFF0B0B0B);
  static const surface = Color(0xFF141414);
  static const surfaceFloat = Color(0xFF1E1E1E);
  static const surfaceElevated = Color(0xFF242424);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFBDBDBD);
  static const textMuted = Color(0xFF8A8A8A);
  static const dividerColor = Color(0xFF2A2A2A);
  static const badgeRed = Color(0xFFD32F2F);
  static const successGreen = Color(0xFF25D366);

  // ── Legacy aliases (kept for widgets that haven't migrated yet) ──
  static const cream = surfaceFloat;
  static const warmWhite = surfaceFloat;
  static const softGray = textMuted;
  static const darkText = textPrimary;
  static const bubbleMe = rose;
  static const bubbleHer = lavender;

  // ── Gradients ──
  static const blush = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7B9CB), Color(0xFFE8A0B4)],
  );
  static const dusk = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A0B4), Color(0xFFB8A0D4)],
  );
  static const lavenderGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCDBBEA), Color(0xFFB8A0D4)],
  );
  // Dark screen gradient — used as backdrop in all main screens.
  static const screen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B0B0B), Color(0xFF141414)],
  );
}

const kSoftShadow = [
  BoxShadow(
    color: Color(0x28000000),
    blurRadius: 20,
    offset: Offset(0, 8),
  ),
];

class GataTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: GataColors.rose,
          onPrimary: Colors.white,
          secondary: GataColors.lavender,
          onSecondary: Colors.white,
          error: Color(0xFFCF6679),
          onError: Colors.white,
          surface: GataColors.surface,
          onSurface: GataColors.textPrimary,
        ),
        scaffoldBackgroundColor: GataColors.bg,
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge: GoogleFonts.playfairDisplay(
            color: GataColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: GoogleFonts.nunito(
            color: GataColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          bodyLarge: GoogleFonts.nunito(
            color: GataColors.textPrimary,
            fontSize: 16,
          ),
          bodyMedium: GoogleFonts.nunito(
            color: GataColors.textSecondary,
            fontSize: 14,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: GataColors.bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.nunito(
            color: GataColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: const IconThemeData(color: GataColors.textPrimary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: GataColors.surfaceFloat,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: GataColors.rose, width: 1.5),
          ),
          hintStyle: const TextStyle(color: GataColors.textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            minimumSize: const Size(0, 48),
            textStyle:
                GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: GataColors.surfaceFloat,
          selectedItemColor: GataColors.textPrimary,
          unselectedItemColor: GataColors.textMuted,
          type: BottomNavigationBarType.fixed,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: GataColors.surfaceFloat,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: GataColors.surfaceElevated,
          contentTextStyle: TextStyle(color: GataColors.textPrimary),
          behavior: SnackBarBehavior.floating,
        ),
        dividerColor: GataColors.dividerColor,
      );
}
