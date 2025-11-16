import 'package:flutter/material.dart';

/// App-wide constants for BarterBrAIn
class AppConstants {
  // App Info
  static const String appName = 'BarterBrAIn';
  static const String appTagline = 'Campus Exchange, Elevated';
  
  // Brand Colors
  static const Color primaryColor = Color(0xFFE76D39); // Orange
  static const Color secondaryColor = Color(0xFF22263E); // Dark Grey Blue
  static const Color tertiaryColor = Color(0xFF000000); // Black
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color successColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFFCC00);
  static const Color infoColor = Color(0xFF007AFF);
  
  // iOS System Colors (for subtle elements)
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);
  
  // Glass Effect Colors
  static const Color glassBackground = Color(0xF0FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);
  
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
  
  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusCircle = 999.0;
  
  // Accessibility
  static const double minTapSize = 44.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Button Scale on Tap
  static const double buttonPressScale = 0.97;
  
  // Asset Paths
  static const String assetDataPath = 'assets/data/';
  static const String assetImagesPath = 'assets/images/';
  static const String universitiesJsonPath = '${assetDataPath}universities_us.json';
  
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String universitiesCollection = 'universities';
  static const String productsCollection = 'products';
  static const String chatsCollection = 'chats';
  static const String emailOtpsCollection = 'emailOtps';
  static const String emailOtpsDebugCollection = 'emailOtpsDebug';
  
  // Storage Paths
  static const String profilePhotosPath = 'profile_photos';
  static const String productImagesPath = 'product_images';
  
  // OTP Configuration
  static const int otpLength = 6;
  static const int otpValidityMinutes = 5;
  static const int maxOtpAttempts = 3;
  
  // Gender Options
  static const List<String> genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];
  
  // Validation
  static const int minPasswordLength = 8;
  static const String eduDomainSuffix = '.edu';
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorInvalidEmail = 'Please enter a valid .edu email address.';
  static const String errorInvalidOtp = 'Invalid OTP. Please try again.';
  static const String errorOtpExpired = 'OTP has expired. Please request a new one.';
  static const String errorPasswordTooShort = 'Password must be at least 8 characters.';
  
  // Success Messages
  static const String successOtpSent = 'OTP sent to your email!';
  static const String successOtpVerified = 'Email verified successfully!';
  static const String successProfileCreated = 'Profile created successfully!';
}

