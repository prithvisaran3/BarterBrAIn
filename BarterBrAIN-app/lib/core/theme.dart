import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';
import 'typography.dart';

/// App theme configuration with iOS-inspired design
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        tertiary: AppConstants.tertiaryColor,
        error: AppConstants.errorColor,
        surface: AppConstants.backgroundColor,
        surfaceContainerHighest: AppConstants.backgroundSecondary,
        onPrimary: AppConstants.textOnPrimary,
        onSecondary: AppConstants.textOnSecondary,
        onError: Colors.white,
        onSurface: AppConstants.textPrimary,
      ),
      
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      
      // Typography - Using centralized typography constants
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        titleLarge: AppTypography.headlineMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.systemGray6,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: AppConstants.errorColor,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: const BorderSide(
            color: AppConstants.errorColor,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingM,
        ),
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppConstants.systemGray2,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppConstants.textSecondary,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          minimumSize: const Size(double.infinity, 50),
          textStyle: AppTypography.buttonLarge,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: AppTypography.buttonMedium,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppConstants.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          side: const BorderSide(
            color: AppConstants.systemGray5,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppConstants.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXl),
          ),
        ),
        elevation: 0,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.textPrimary,
        contentTextStyle: AppTypography.labelLarge.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppConstants.systemGray5,
        thickness: 1,
        space: 1,
      ),
    );
  }
  
  /// Enhanced glass morphism effect for floating elements (iOS-inspired liquid glass)
  static BoxDecoration glassDecoration({
    Color? color,
    double blur = 10,
    double opacity = 0.85,
    double borderRadius = AppConstants.radiusL,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.4),
        width: 1,
      ),
      boxShadow: [
        // Outer shadow (depth)
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 30,
          offset: const Offset(0, 15),
          spreadRadius: -5,
        ),
        // Inner highlight (glass effect)
        BoxShadow(
          color: Colors.white.withOpacity(0.6),
          blurRadius: 10,
          offset: const Offset(0, -2),
          spreadRadius: -2,
        ),
      ],
    );
  }
  
  /// Liquid glass effect for navigation bars and floating UI
  static BoxDecoration liquidGlassDecoration({
    Color? backgroundColor,
    double opacity = 0.88,
    double borderRadius = AppConstants.radiusXl,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          (backgroundColor ?? Colors.white).withOpacity(opacity),
          (backgroundColor ?? Colors.white).withOpacity(opacity * 0.95),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.5),
        width: 1.5,
      ),
      boxShadow: [
        // Primary shadow
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 40,
          offset: const Offset(0, 20),
          spreadRadius: -10,
        ),
        // Ambient shadow
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        // Inner glow
        BoxShadow(
          color: Colors.white.withOpacity(0.7),
          blurRadius: 8,
          offset: const Offset(0, -1),
          spreadRadius: -3,
        ),
      ],
    );
  }
  
  /// Soft shadow for elevated elements
  static List<BoxShadow> softShadow({
    Color? color,
    double opacity = 0.1,
  }) {
    return [
      BoxShadow(
        color: (color ?? Colors.black).withOpacity(opacity),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

