import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primarySeed = Color(0xFF6750A4);
  static const Color _primaryAccent = Color(0xFF9A82DB);
  static const Color _surfaceDark = Color(0xFF0A0A0A);
  static const Color _surfaceContainerDark = Color(0xFF121212);
  static const Color _surfaceContainerHighDark = Color(0xFF1E1E1E);
  static const Color _accentCyan = Color(0xFF00BCD4);
  static const Color _accentAmber = Color(0xFFFFB300);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
      surface: _surfaceDark,
      onSurface: Colors.white,
      primary: _primaryAccent,
      secondary: _accentCyan,
      tertiary: _accentAmber,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: _surfaceContainerHighDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _surfaceContainerDark,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceContainerDark,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          );
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: Colors.grey[800],
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
        size: 24,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Colors.white60,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          color: Colors.white54,
        ),
      ),
      extensions: [
        GalleryThemeExtension(
          gridBackgroundColor: const Color(0xFF0D0D0D),
          thumbnailPlaceholderColor: const Color(0xFF1A1A1A),
          selectionOverlayColor: _primaryAccent.withOpacity(0.3),
          selectedBorderColor: _primaryAccent,
          successColor: const Color(0xFF4CAF50),
          warningColor: const Color(0xFFFF9800),
          errorColor: const Color(0xFFF44336),
          infoColor: _accentCyan,
        ),
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceContainerHighDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surfaceContainerHighDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surfaceContainerHighDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [
        GalleryThemeExtension(
          gridBackgroundColor: const Color(0xFFF5F5F5),
          thumbnailPlaceholderColor: const Color(0xFFE0E0E0),
          selectionOverlayColor: _primaryAccent.withOpacity(0.2),
          selectedBorderColor: _primaryAccent,
          successColor: const Color(0xFF4CAF50),
          warningColor: const Color(0xFFFF9800),
          errorColor: const Color(0xFFF44336),
          infoColor: _accentCyan,
        ),
      ],
    );
  }
}

class GalleryThemeExtension extends ThemeExtension<GalleryThemeExtension> {
  final Color gridBackgroundColor;
  final Color thumbnailPlaceholderColor;
  final Color selectionOverlayColor;
  final Color selectedBorderColor;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color infoColor;

  const GalleryThemeExtension({
    required this.gridBackgroundColor,
    required this.thumbnailPlaceholderColor,
    required this.selectionOverlayColor,
    required this.selectedBorderColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.infoColor,
  });

  @override
  ThemeExtension<GalleryThemeExtension> copyWith({
    Color? gridBackgroundColor,
    Color? thumbnailPlaceholderColor,
    Color? selectionOverlayColor,
    Color? selectedBorderColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? infoColor,
  }) {
    return GalleryThemeExtension(
      gridBackgroundColor: gridBackgroundColor ?? this.gridBackgroundColor,
      thumbnailPlaceholderColor: thumbnailPlaceholderColor ?? this.thumbnailPlaceholderColor,
      selectionOverlayColor: selectionOverlayColor ?? this.selectionOverlayColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      infoColor: infoColor ?? this.infoColor,
    );
  }

  @override
  ThemeExtension<GalleryThemeExtension> lerp(ThemeExtension<GalleryThemeExtension>? other, double t) {
    if (other is! GalleryThemeExtension) return this;
    return GalleryThemeExtension(
      gridBackgroundColor: Color.lerp(gridBackgroundColor, other.gridBackgroundColor, t)!,
      thumbnailPlaceholderColor: Color.lerp(thumbnailPlaceholderColor, other.thumbnailPlaceholderColor, t)!,
      selectionOverlayColor: Color.lerp(selectionOverlayColor, other.selectionOverlayColor, t)!,
      selectedBorderColor: Color.lerp(selectedBorderColor, other.selectedBorderColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
    );
  }
}