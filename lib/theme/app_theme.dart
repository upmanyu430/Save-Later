import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:save_later/config/app_constants.dart';

class AppTheme {
  // Pastel color palette
  static const Color background = Color(0xFFF4F0EB);
  static const Color primary = Color(0xFFFF9EAA); // Pastel Pink
  static const Color secondary = Color(0xFF3AC19F); // Pastel Green
  static const Color accent = Color(0xFFFFD166); // Pastel Yellow
  static const Color cardColor = Color(0xFFFFFFFF);
  
  static const Color border = Color(0xFF1C1C1C); // Very dark gray/black
  
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: cardColor,
        onPrimary: border,
        onSecondary: border,
        onSurface: border,
      ),
      textTheme: GoogleFonts.gabaritoTextTheme().apply(
        bodyColor: border,
        displayColor: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        iconTheme: const IconThemeData(color: border, size: AppDimensions.iconSizeLg),
        titleTextStyle: GoogleFonts.gabarito(
          color: border,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
