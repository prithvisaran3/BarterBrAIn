import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/university_service.dart';
import '../../models/user_model.dart';
import '../../core/constants.dart';

class SignupUniversityView extends StatefulWidget {
  SignupUniversityView({super.key});

  @override
  State<SignupUniversityView> createState() => _SignupUniversityViewState();
}

class _SignupUniversityViewState extends State<SignupUniversityView>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final _universityService = Get.find<UniversityService>();
  final _selectedUniversity = Rx<UniversityModel?>(null);

  late AnimationController _heroController;
  late AnimationController _formController;

  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..forward();

    _formController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    )..forward();

    _heroFade = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOut,
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroController,
        curve: Curves.easeOutCubic,
      ),
    );

    _formFade = CurvedAnimation(
      parent: _formController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _heroController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _heroFade,
                child: SlideTransition(
                  position: _heroSlide,
                  child: _buildHeroCard(context),
                ),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              FadeTransition(
                opacity: _formFade,
                child: _buildForm(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      decoration: BoxDecoration(
        color: AppConstants.secondaryColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppConstants.secondaryColor.withOpacity(0.25),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join Your Campus',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Verify your .edu email to unlock a trusted marketplace just for your university.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: AppConstants.spacingS),
              Text(
                'Step 1 of 4 • Verification',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(1, 4),
          const SizedBox(height: AppConstants.spacingXl),
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppConstants.systemGray6,
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Column(
              children: [
                _buildBenefitRow(Icons.verified, 'Verified .edu emails only'),
                const SizedBox(height: AppConstants.spacingS),
                _buildBenefitRow(Icons.lock, 'OTP secured onboarding'),
                const SizedBox(height: AppConstants.spacingS),
                _buildBenefitRow(Icons.schedule, 'Under a minute to verify'),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),
          Obx(() {
            if (_universityService.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            return DropdownButtonFormField<UniversityModel>(
              value: _selectedUniversity.value,
              decoration: const InputDecoration(
                labelText: 'University',
                hintText: 'Select your university',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: _universityService.universities.map((uni) {
                return DropdownMenuItem(
                  value: uni,
                  child: Text(
                    uni.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                _selectedUniversity.value = value;
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your university';
                }
                return null;
              },
              isExpanded: true,
              menuMaxHeight: 400,
            );
          }),
          const SizedBox(height: AppConstants.spacingM),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'University Email',
              hintText: 'your.email@university.edu',
              prefixIcon: Icon(Icons.email_outlined),
              helperText: 'Must be a valid .edu email address',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your university email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              if (!value.toLowerCase().endsWith(AppConstants.eduDomainSuffix)) {
                return 'Please enter a .edu email address';
              }
              
              // Any .edu email is now accepted - no domain matching required
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingXl),
          _buildInfoCard(context),
          const SizedBox(height: AppConstants.spacingXl),
          Obx(
            () => Column(
              children: [
                CNButton(
                  label: 'Send Verification Code',
                  onPressed: _authController.isLoading.value ? null : _handleSendOtp,
                ),
                if (_authController.isLoading.value) ...[
                  const SizedBox(height: AppConstants.spacingS),
                  const CupertinoActivityIndicator(),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppConstants.primaryColor, size: 18),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Text(
              'We\'ll send a one-time passcode to your .edu email. Keep your inbox handy!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
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

  Future<void> _handleSendOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await _authController.sendOtp(
        _emailController.text.trim(),
        _selectedUniversity.value!.id,
      );
      
      if (success) {
        Get.toNamed('/otp-verify');
      }
    }
  }
}

