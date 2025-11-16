import 'package:flutter/material.dart';
import 'constants.dart';

/// Typography constants for consistent text styling throughout the app
class AppTypography {
  // Font Family - San Francisco Pro
  static const String fontFamily = '.SF Pro Display';
  
  // Font Sizes
  static const double fontSizeXs = 11.0;
  static const double fontSizeS = 13.0;
  static const double fontSizeM = 15.0;
  static const double fontSizeL = 17.0;
  static const double fontSizeXl = 20.0;
  static const double fontSizeXxl = 22.0;
  static const double fontSize3xl = 28.0;
  static const double fontSize4xl = 34.0;
  
  // Font Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  // Line Heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.5;
  
  // Letter Spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = -0.2;
  static const double letterSpacingWide = 0.0;
  
  // Text Styles - Display
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize4xl,
    fontWeight: fontWeightBold,
    letterSpacing: letterSpacingTight,
    color: AppConstants.textPrimary,
    height: lineHeightTight,
  );
  
  static TextStyle get displayMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize3xl,
    fontWeight: fontWeightBold,
    letterSpacing: letterSpacingNormal,
    color: AppConstants.textPrimary,
    height: lineHeightTight,
  );
  
  static TextStyle get displaySmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXxl,
    fontWeight: fontWeightSemibold,
    letterSpacing: letterSpacingNormal,
    color: AppConstants.textPrimary,
    height: lineHeightNormal,
  );
  
  // Text Styles - Headline
  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXl,
    fontWeight: fontWeightSemibold,
    color: AppConstants.textPrimary,
    height: lineHeightNormal,
  );
  
  static TextStyle get headlineMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeL,
    fontWeight: fontWeightSemibold,
    color: AppConstants.textPrimary,
    height: lineHeightNormal,
  );
  
  // Text Styles - Body
  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeL,
    fontWeight: fontWeightRegular,
    color: AppConstants.textPrimary,
    height: lineHeightRelaxed,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeM,
    fontWeight: fontWeightRegular,
    color: AppConstants.textPrimary,
    height: lineHeightRelaxed,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeS,
    fontWeight: fontWeightRegular,
    color: AppConstants.textSecondary,
    height: lineHeightNormal,
  );
  
  // Text Styles - Label
  static TextStyle get labelLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeM,
    fontWeight: fontWeightSemibold,
    color: AppConstants.textPrimary,
    height: lineHeightNormal,
  );
  
  static TextStyle get labelMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeS,
    fontWeight: fontWeightMedium,
    color: AppConstants.textSecondary,
    height: lineHeightNormal,
  );
  
  static TextStyle get labelSmall => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: fontWeightMedium,
    color: AppConstants.textSecondary,
    height: lineHeightNormal,
  );
  
  // Text Styles - Button
  static TextStyle get buttonLarge => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeL,
    fontWeight: fontWeightSemibold,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );
  
  static TextStyle get buttonMedium => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeM,
    fontWeight: fontWeightSemibold,
    height: lineHeightNormal,
  );
  
  // Text Styles - Caption
  static TextStyle get caption => const TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSizeXs,
    fontWeight: fontWeightRegular,
    color: AppConstants.textSecondary,
    height: lineHeightNormal,
  );
  
  // Helper method to create custom text style
  static TextStyle custom({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize ?? fontSizeM,
      fontWeight: fontWeight ?? fontWeightRegular,
      color: color ?? AppConstants.textPrimary,
      height: height ?? lineHeightNormal,
      letterSpacing: letterSpacing ?? letterSpacingWide,
    );
  }
}

