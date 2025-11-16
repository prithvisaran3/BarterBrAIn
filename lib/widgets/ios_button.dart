import 'package:flutter/material.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'dart:io';
import '../core/constants.dart';

/// Native iOS Liquid Glass button with fallback for other platforms
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isDestructive;
  final double? width;
  final double height;
  final IconData? icon;

  const IOSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDestructive = false,
    this.width,
    this.height = 50,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Use native iOS button on Apple platforms
    if (Platform.isIOS || Platform.isMacOS) {
      if (icon != null) {
        // Icon button variant
        return SizedBox(
          width: width,
          height: height,
          child: CNButton.icon(
            icon: CNSymbol(_mapIconToSymbol(icon!)),
            onPressed: isLoading ? null : onPressed,
          ),
        );
      }
      
      // Standard button
      return SizedBox(
        width: width,
        height: height,
        child: CNButton(
          label: text,
          onPressed: isLoading ? null : onPressed,
        ),
      );
    }

    // Fallback for non-Apple platforms
    return _FallbackButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isSecondary: isSecondary,
      isDestructive: isDestructive,
      width: width,
      height: height,
      icon: icon,
    );
  }

  // Map Material Icons to SF Symbols
  String _mapIconToSymbol(IconData icon) {
    // Map common icons to SF Symbol names
    if (icon == Icons.logout) return 'rectangle.portrait.and.arrow.right';
    if (icon == Icons.add) return 'plus';
    if (icon == Icons.add_circle) return 'plus.circle.fill';
    if (icon == Icons.delete) return 'trash.fill';
    if (icon == Icons.edit) return 'pencil';
    if (icon == Icons.save) return 'checkmark';
    if (icon == Icons.camera_alt) return 'camera.fill';
    if (icon == Icons.photo_library) return 'photo.fill';
    if (icon == Icons.check) return 'checkmark';
    if (icon == Icons.close) return 'xmark';
    if (icon == Icons.arrow_back) return 'chevron.left';
    if (icon == Icons.arrow_forward) return 'chevron.right';
    if (icon == Icons.settings) return 'gearshape.fill';
    
    // Default fallback
    return 'circle.fill';
  }
}

/// Fallback button for non-Apple platforms
class _FallbackButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isDestructive;
  final double? width;
  final double height;
  final IconData? icon;

  const _FallbackButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDestructive = false,
    this.width,
    this.height = 50,
    this.icon,
  });

  Color get _backgroundColor {
    if (isDestructive) return AppConstants.errorColor;
    if (isSecondary) return AppConstants.secondaryColor;
    return AppConstants.primaryColor;
  }

  Color get _textColor {
    if (isSecondary) return AppConstants.textOnSecondary;
    return AppConstants.textOnPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: text,
      child: Material(
        color: onPressed == null ? AppConstants.systemGray4 : _backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Container(
            width: width,
            height: height,
            constraints: const BoxConstraints(minWidth: AppConstants.minTapSize),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: _textColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                        ],
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
