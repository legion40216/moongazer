import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF000000);
  static const surface = Color(0xFF0A0F1E);
  static const card = Color(0xFF0D1220);
  static const cardBorder = Color(0xFF1A2A1A);

  static const accent = Color(0xFF00FF00); // classic lime green
  static const accentDim = Color(0xFF44CC44);
  static const accentFaint = Color(0xFF1A3A1A);

  static const textPrimary = Color(0xFF00FF00);
  static const textSecondary = Color(0xFF66BB66);
  static const textDim = Color(0xFF335533);

  static const moonSurface = Color(0xFFE8E0C8);
  static const moonShadow = Color(0xFF050A15);
  static const moonGlow = Color(0xFFFFFFAA);
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle mono({
    double size = 13,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.spaceMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
      );

  static TextStyle label({double size = 11}) => mono(
        size: size,
        color: AppColors.textSecondary,
      );

  static TextStyle value({double size = 13}) => mono(
        size: size,
        color: AppColors.textPrimary,
        weight: FontWeight.w700,
      );

  static TextStyle heading({double size = 15}) => mono(
        size: size,
        color: AppColors.accentDim,
        weight: FontWeight.w700,
      );

  static TextStyle hero({double size = 22}) => mono(
        size: size,
        color: AppColors.accent,
        weight: FontWeight.w700,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accentDim,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        textTheme: GoogleFonts.spaceMonoTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        cardTheme: const CardTheme(
          color: AppColors.card,
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.cardBorder,
          thickness: 1,
        ),
        iconTheme: const IconThemeData(color: AppColors.accentDim),
      );
}
