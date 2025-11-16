import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/ios_button.dart';
import '../../core/constants.dart';

class OtpVerifyView extends StatelessWidget {
  OtpVerifyView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpControllers = List.generate(
    AppConstants.otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(
    AppConstants.otpLength,
    (_) => FocusNode(),
  );
  final _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.spacingM),
                
                // Title
                Text(
                  'Check Your Email',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                
                const SizedBox(height: AppConstants.spacingS),
                
                Text(
                  'We sent a code to ${_authController.pendingEmail ?? "your email"}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                ),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // Step Indicator
                _buildStepIndicator(2, 4),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // OTP Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    AppConstants.otpLength,
                    (index) => _buildOtpField(index),
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingL),
                
                // Resend OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: _handleResendOtp,
                      child: const Text('Resend'),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Create Password',
                    hintText: 'At least 8 characters',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return AppConstants.errorPasswordTooShort;
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppConstants.spacingM),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // Verify Button
                Obx(() => IOSButton(
                      text: 'Verify & Continue',
                      onPressed: _authController.isLoading.value ? null : _handleVerifyOtp,
                      isLoading: _authController.isLoading.value,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep, int totalSteps) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(
              right: index < totalSteps - 1 ? AppConstants.spacingS : 0,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? AppConstants.primaryColor
                  : AppConstants.systemGray5,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < AppConstants.otpLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }

  Future<void> _handleVerifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final otp = _otpControllers.map((c) => c.text).join();
      
      if (otp.length != AppConstants.otpLength) {
        Get.snackbar(
          'Error',
          'Please enter the complete verification code',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      final success = await _authController.verifyOtp(
        otp,
        _passwordController.text,
      );
      
      if (success) {
        Get.offNamed('/profile-setup');
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_authController.pendingEmail != null &&
        _authController.pendingUniversityId != null) {
      await _authController.sendOtp(
        _authController.pendingEmail!,
        _authController.pendingUniversityId!,
      );
    }
  }
}

