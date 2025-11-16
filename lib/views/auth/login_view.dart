import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();

  late AnimationController _heroController;
  late AnimationController _formController;
  late AnimationController _pulseController;

  late Animation<double> _heroFade;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    _formController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutCubic,
    );

    _formFade = CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOut,
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _heroController.dispose();
    _formController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          // Background accents
          Positioned(
            top: -80,
            right: -60,
            child: _buildAccentCircle(AppConstants.primaryColor.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 40,
            left: -40,
            child: _buildAccentCircle(AppConstants.secondaryColor.withOpacity(0.1), size: 180),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.spacingS),
                    FadeTransition(
                      opacity: _heroFade,
                      child: _buildHeroCard(),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    SlideTransition(
                      position: _formSlide,
                      child: FadeTransition(
                        opacity: _formFade,
                        child: _buildForm(),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                    _buildDivider(),
                    const SizedBox(height: AppConstants.spacingM),
                    _buildSignUpButton(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    _buildBadge(),
                    const SizedBox(height: AppConstants.spacingS),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentCircle(Color color, {double size = 220}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 0.95 + (_pulseController.value * 0.1);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        Image.asset(
          'assets/logo/BarterBrAIn-logo.png',
          width: 200,
          height: 100,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppConstants.spacingM),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'your.email@university.edu',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingM),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Obx(
            () => Column(
              children: [
                CNButton(
                  label: 'Sign In',
                  onPressed: _authController.isLoading.value ? null : _handleLogin,
                ),
                if (_authController.isLoading.value) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  const CupertinoActivityIndicator(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return CNButton(
      label: 'Create Account',
      onPressed: () => Get.toNamed('/signup'),
    );
  }

  Widget _buildBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: AppConstants.systemGray6,
          borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user,
              size: 16,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              '.edu verified',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await _authController.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        Get.offAllNamed('/main');
      }
    }
  }

  void _handleForgotPassword() {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: AppConstants.spacingM),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'your.email@university.edu',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _authController.resetPassword(_emailController.text.trim());
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
