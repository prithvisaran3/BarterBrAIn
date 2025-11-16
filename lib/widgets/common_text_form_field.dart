import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants.dart';
import '../core/typography.dart';

/// Common text form field widget for consistent input styling throughout the app
class CommonTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final void Function()? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode? autovalidateMode;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  
  const CommonTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.inputFormatters,
    this.autovalidateMode,
    this.fillColor,
    this.contentPadding,
  });
  
  /// Email text field with email keyboard and validation
  const CommonTextFormField.email({
    super.key,
    this.controller,
    this.labelText = 'Email',
    this.hintText = 'your.email@university.edu',
    this.helperText,
    this.errorText,
    this.prefixIcon = const Icon(Icons.email_outlined),
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.fillColor,
    this.contentPadding,
  })  : obscureText = false,
        keyboardType = TextInputType.emailAddress,
        textInputAction = TextInputAction.next,
        textCapitalization = TextCapitalization.none,
        maxLines = 1,
        maxLength = null,
        inputFormatters = null;
  
  /// Password text field with obscured text
  const CommonTextFormField.password({
    super.key,
    this.controller,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.helperText,
    this.errorText,
    this.prefixIcon = const Icon(Icons.lock_outline),
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.fillColor,
    this.contentPadding,
  })  : obscureText = true,
        keyboardType = TextInputType.visiblePassword,
        textInputAction = TextInputAction.done,
        textCapitalization = TextCapitalization.none,
        maxLines = 1,
        maxLength = null,
        inputFormatters = null;
  
  /// Name text field with capitalization
  const CommonTextFormField.name({
    super.key,
    this.controller,
    this.labelText = 'Name',
    this.hintText = 'Enter your name',
    this.helperText,
    this.errorText,
    this.prefixIcon = const Icon(Icons.person_outline),
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.fillColor,
    this.contentPadding,
  })  : obscureText = false,
        keyboardType = TextInputType.name,
        textInputAction = TextInputAction.next,
        textCapitalization = TextCapitalization.words,
        maxLines = 1,
        maxLength = null,
        inputFormatters = null;
  
  /// Phone text field with number keyboard
  const CommonTextFormField.phone({
    super.key,
    this.controller,
    this.labelText = 'Phone',
    this.hintText = 'Enter your phone number',
    this.helperText,
    this.errorText,
    this.prefixIcon = const Icon(Icons.phone_outlined),
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.fillColor,
    this.contentPadding,
  })  : obscureText = false,
        keyboardType = TextInputType.phone,
        textInputAction = TextInputAction.next,
        textCapitalization = TextCapitalization.none,
        maxLines = 1,
        maxLength = null,
        inputFormatters = null;
  
  /// Multiline text field for longer text
  const CommonTextFormField.multiline({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 5,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.fillColor,
    this.contentPadding,
  })  : obscureText = false,
        keyboardType = TextInputType.multiline,
        textInputAction = TextInputAction.newline,
        textCapitalization = TextCapitalization.sentences,
        inputFormatters = null;
  
  /// Search text field
  const CommonTextFormField.search({
    super.key,
    this.controller,
    this.labelText,
    this.hintText = 'Search...',
    this.helperText,
    this.errorText,
    this.prefixIcon = const Icon(Icons.search),
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.autovalidateMode,
    this.fillColor,
    this.contentPadding,
  })  : obscureText = false,
        keyboardType = TextInputType.text,
        textInputAction = TextInputAction.search,
        textCapitalization = TextCapitalization.none,
        maxLines = 1,
        maxLength = null,
        inputFormatters = null;
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      focusNode: focusNode,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      inputFormatters: inputFormatters,
      autovalidateMode: autovalidateMode,
      style: AppTypography.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor ?? AppConstants.systemGray6,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingM,
            ),
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
        hintStyle: AppTypography.bodyLarge.copyWith(
          color: AppConstants.systemGray2,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppConstants.textSecondary,
        ),
        helperStyle: AppTypography.bodySmall,
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppConstants.errorColor,
        ),
      ),
    );
  }
}

