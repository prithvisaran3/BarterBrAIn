import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/ios_button.dart';
import '../../core/constants.dart';

class ProfileSetupView extends StatelessWidget {
  ProfileSetupView({super.key});

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _majorController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final _selectedGender = Rx<String?>(null);
  final _profileImage = Rx<File?>(null);
  final _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: const SizedBox(), // Disable back button
        title: const Text('Complete Profile'),
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
                  'Tell Us About You',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                
                const SizedBox(height: AppConstants.spacingS),
                
                Text(
                  'Complete your profile to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                ),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // Step Indicator
                _buildStepIndicator(3, 4),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // Profile Photo Picker
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Obx(() {
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppConstants.systemGray6,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _profileImage.value != null
                                    ? AppConstants.primaryColor
                                    : AppConstants.systemGray4,
                                width: 3,
                              ),
                              boxShadow: _profileImage.value != null
                                  ? [
                                      BoxShadow(
                                        color: AppConstants.primaryColor.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                              image: _profileImage.value != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage.value!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImage.value == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: AppConstants.systemGray2,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingS),
                
                Center(
                  child: TextButton(
                    onPressed: _showImageSourceDialog,
                    child: Obx(() => Text(
                          _profileImage.value == null
                              ? 'Add Profile Photo (Optional)'
                              : 'Change Photo',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // First Name
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                    hintText: 'John',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppConstants.spacingM),
                
                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                    hintText: 'Doe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppConstants.spacingM),
                
                // Gender Dropdown
                Obx(() => DropdownButtonFormField<String>(
                      value: _selectedGender.value,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        hintText: 'Select your gender',
                        prefixIcon: Icon(Icons.wc_outlined),
                      ),
                      items: AppConstants.genderOptions.map((gender) {
                        return DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        _selectedGender.value = value;
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select your gender';
                        }
                        return null;
                      },
                    )),
                
                const SizedBox(height: AppConstants.spacingM),
                
                // Major/Field of Study
                TextFormField(
                  controller: _majorController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Major / Field of Study',
                    hintText: 'Computer Science',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your major';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppConstants.spacingXl),
                
                // Finish Button
                Obx(() => IOSButton(
                      text: 'Finish',
                      onPressed: _authController.isLoading.value ? null : _handleFinish,
                      isLoading: _authController.isLoading.value,
                      icon: Icons.check_circle_outline,
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

  void _showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.systemGray3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.tertiaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppConstants.primaryColor),
                ),
                title: const Text('Take Photo'),
                onTap: () {
                  Get.back();
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppConstants.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppConstants.secondaryColor),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Get.back();
                  _pickFromGallery();
                },
              ),
              if (_profileImage.value != null)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete, color: AppConstants.errorColor),
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Get.back();
                    _profileImage.value = null;
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isDismissible: true,
    );
  }

  Future<void> _takePhoto() async {
    print('📸 DEBUG [ProfileSetup]: Opening camera...');
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('✅ DEBUG [ProfileSetup]: Photo taken: ${image.path}');
        _profileImage.value = File(image.path);
      } else {
        print('⚠️ DEBUG [ProfileSetup]: No photo taken');
      }
    } catch (e) {
      print('❌ DEBUG [ProfileSetup]: Error taking photo: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    print('📸 DEBUG [ProfileSetup]: Opening gallery...');
    
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        print('✅ DEBUG [ProfileSetup]: Image selected: ${image.path}');
        _profileImage.value = File(image.path);
      } else {
        print('⚠️ DEBUG [ProfileSetup]: No image selected');
      }
    } catch (e) {
      print('❌ DEBUG [ProfileSetup]: Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleFinish() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await _authController.completeProfileSetup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender.value!,
        major: _majorController.text.trim(),
        profilePhoto: _profileImage.value,
      );
      
      if (success) {
        Get.offAllNamed('/main');
      }
    }
  }
}

