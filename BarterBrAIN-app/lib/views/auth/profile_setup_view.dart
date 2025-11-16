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
                    onTap: _pickImage,
                    child: Obx(() {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppConstants.systemGray6,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppConstants.systemGray4,
                            width: 2,
                          ),
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
                      );
                    }),
                  ),
                ),
                
                const SizedBox(height: AppConstants.spacingS),
                
                Center(
                  child: TextButton(
                    onPressed: _pickImage,
                    child: const Text('Add Profile Photo'),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        _profileImage.value = File(image.path);
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
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

