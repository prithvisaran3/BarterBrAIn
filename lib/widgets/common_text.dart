import 'package:flutter/material.dart';
import '../core/typography.dart';
import '../core/constants.dart';

/// Common text widget for consistent typography throughout the app
class CommonText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final TextDecoration? decoration;
  
  const CommonText(
    this.text, {
    super.key,
    this.style,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.decoration,
  });
  
  // Named constructors for common text styles
  
  /// Display large text (34px, bold)
  const CommonText.displayLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Display medium text (28px, bold)
  const CommonText.displayMedium(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Display small text (22px, semibold)
  const CommonText.displaySmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Headline text (20px, semibold)
  const CommonText.headline(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Body large text (17px, regular)
  const CommonText.bodyLarge(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Body medium text (15px, regular) - Default
  const CommonText.bodyMedium(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Body small text (13px, regular, secondary color)
  const CommonText.bodySmall(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Label text (15px, semibold)
  const CommonText.label(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Caption text (11px, regular, secondary color)
  const CommonText.caption(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Button text (17px, semibold)
  const CommonText.button(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        fontSize = null,
        fontWeight = null,
        decoration = null;
  
  /// Error text (red color)
  const CommonText.error(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        color = AppConstants.errorColor,
        decoration = null;
  
  /// Success text (green color)
  const CommonText.success(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        color = AppConstants.successColor,
        decoration = null;
  
  /// Primary colored text
  const CommonText.primary(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        color = AppConstants.primaryColor,
        decoration = null;
  
  /// Secondary colored text
  const CommonText.secondary(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  })  : style = null,
        color = AppConstants.textSecondary,
        decoration = null;
  
  @override
  Widget build(BuildContext context) {
    // Determine which base style to use based on constructor
    TextStyle baseStyle;
    
    if (style != null) {
      baseStyle = style!;
    } else {
      // Map named constructors to appropriate styles
      if (runtimeType.toString().contains('displayLarge')) {
        baseStyle = AppTypography.displayLarge;
      } else if (runtimeType.toString().contains('displayMedium')) {
        baseStyle = AppTypography.displayMedium;
      } else if (runtimeType.toString().contains('displaySmall')) {
        baseStyle = AppTypography.displaySmall;
      } else if (runtimeType.toString().contains('headline')) {
        baseStyle = AppTypography.headlineLarge;
      } else if (runtimeType.toString().contains('bodyLarge')) {
        baseStyle = AppTypography.bodyLarge;
      } else if (runtimeType.toString().contains('bodySmall')) {
        baseStyle = AppTypography.bodySmall;
      } else if (runtimeType.toString().contains('label')) {
        baseStyle = AppTypography.labelLarge;
      } else if (runtimeType.toString().contains('caption')) {
        baseStyle = AppTypography.caption;
      } else if (runtimeType.toString().contains('button')) {
        baseStyle = AppTypography.buttonLarge;
      } else {
        baseStyle = AppTypography.bodyMedium;
      }
    }
    
    // Apply custom overrides
    final finalStyle = baseStyle.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
    );
    
    return Text(
      text,
      style: finalStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

