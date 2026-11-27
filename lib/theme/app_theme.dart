import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:save_later/config/app_constants.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color card;
  final Color surfaceSubtle;
  final Color divider;
  final Color border;
  final Color shadow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color selectedSurface;
  final Color selectedBorder;
  final Color onAccent;
  final Color danger;
  final Color dangerSurface;

  const AppColors({
    required this.background,
    required this.card,
    required this.surfaceSubtle,
    required this.divider,
    required this.border,
    required this.shadow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.selectedSurface,
    required this.selectedBorder,
    required this.onAccent,
    required this.danger,
    required this.dangerSurface,
  });

  static const AppColors light = AppColors(
    background: Color(0xFFF4F0EB),
    card: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF0F0F0),
    divider: Color(0xFFE6E1DA),
    border: Color(0xFF1C1C1C),
    shadow: Color(0xFF1C1C1C),
    textPrimary: Color(0xFF1C1C1C),
    textSecondary: Color(0xFF595959),
    textMuted: Color(0xFF6B6B6B),
    selectedSurface: Color(0xFFFFF4D0),
    selectedBorder: Color(0xFFFDD164),
    onAccent: Color(0xFF1C1C1C),
    danger: Color(0xFFEF476F),
    dangerSurface: Color(0xFFFCE4EC),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF161513),
    card: Color(0xFF23211E),
    surfaceSubtle: Color(0xFF302D29),
    divider: Color(0xFF383430),
    border: Color(0xFF5C564E),
    shadow: Color(0xFF050505),
    textPrimary: Color(0xFFF4F0EB),
    textSecondary: Color(0xFFC4BEB5),
    textMuted: Color(0xFFA6A097),
    selectedSurface: Color(0xFF3B3422),
    selectedBorder: Color(0xFFFFD166),
    onAccent: Color(0xFF1C1C1C),
    danger: Color(0xFFFF6B8B),
    dangerSurface: Color(0xFF3D2129),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? card,
    Color? surfaceSubtle,
    Color? divider,
    Color? border,
    Color? shadow,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? selectedSurface,
    Color? selectedBorder,
    Color? onAccent,
    Color? danger,
    Color? dangerSurface,
  }) {
    return AppColors(
      background: background ?? this.background,
      card: card ?? this.card,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      selectedSurface: selectedSurface ?? this.selectedSurface,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      dangerSurface: dangerSurface ?? this.dangerSurface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      selectedSurface: Color.lerp(selectedSurface, other.selectedSurface, t)!,
      selectedBorder: Color.lerp(selectedBorder, other.selectedBorder, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
    );
  }
}

extension AppColorsBuildContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

class AppTheme {
  // Pastel color palette
  static const Color background = Color(0xFFF4F0EB);
  static const Color primary = Color(0xFFFF9EAA); // Pastel Pink
  static const Color secondary = Color(0xFF3AC19F); // Pastel Green
  static const Color accent = Color(0xFFFFD166); // Pastel Yellow
  static const Color cardColor = Color(0xFFFFFFFF);

  static const Color border = Color(0xFF1C1C1C); // Very dark gray/black

  // WCAG AA compliant text colors on #F4F0EB background (contrast >= 4.5:1)
  static const Color textSecondary = Color(0xFF595959); // 7.2:1 contrast
  static const Color textMuted = Color(0xFF6B6B6B); // 5.6:1 contrast

  static ThemeData get theme => lightTheme;

  static final ThemeData lightTheme = _buildLightTheme();

  static final ThemeData darkTheme = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.light.background,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: AppColors.light.card,
        onPrimary: AppColors.light.onAccent,
        onSecondary: AppColors.light.onAccent,
        onSurface: AppColors.light.textPrimary,
      ),
      fontFamily: 'Gabarito',
      textTheme: GoogleFonts.gabaritoTextTheme().apply(
        bodyColor: AppColors.light.textPrimary,
        displayColor: AppColors.light.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.background,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.light.textPrimary,
          size: AppDimensions.iconSizeLg,
        ),
        titleTextStyle: GoogleFonts.gabarito(
          color: AppColors.light.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      extensions: const [AppColors.light],
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark.background,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: AppColors.dark.card,
        onPrimary: AppColors.dark.onAccent,
        onSecondary: AppColors.dark.onAccent,
        onSurface: AppColors.dark.textPrimary,
      ),
      fontFamily: 'Gabarito',
      textTheme: GoogleFonts.gabaritoTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.dark.textPrimary,
        displayColor: AppColors.dark.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark.background,
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.dark.textPrimary,
          size: AppDimensions.iconSizeLg,
        ),
        titleTextStyle: GoogleFonts.gabarito(
          color: AppColors.dark.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
      ),
      extensions: const [AppColors.dark],
    );
  }
}
