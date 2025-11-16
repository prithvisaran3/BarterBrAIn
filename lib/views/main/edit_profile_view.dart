import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../services/firebase_service.dart';
import '../../widgets/common_text_form_field.dart';
import '../../widgets/ios_button.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _authController = Get.find<AuthController>();
  final _firebaseService = Get.find<FirebaseService>();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _majorController;

  File? _selectedImage;
  String? _selectedGender;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final user = _authController.userModel.value;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _majorController = TextEditingController(text: user?.major ?? '');
    _selectedGender = user?.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    print('📸 DEBUG [EditProfile]: Opening image picker...');

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ DEBUG [EditProfile]: Image selected: ${image.path}');
        setState(() {
          _selectedImage = File(image.path);
        });
      } else {
        print('⚠️ DEBUG [EditProfile]: No image selected');
      }
    } catch (e) {
      print('❌ DEBUG [EditProfile]: Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _takePhoto() async {
    print('📸 DEBUG [EditProfile]: Opening camera...');

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ DEBUG [EditProfile]: Photo taken: ${image.path}');
        setState(() {
          _selectedImage = File(image.path);
        });
      } else {
        print('⚠️ DEBUG [EditProfile]: No photo taken');
      }
    } catch (e) {
      print('❌ DEBUG [EditProfile]: Error taking photo: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
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
                  _pickImage();
                },
              ),
              if (_authController.userModel.value?.profilePhotoUrl != null)
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
                    setState(() {
                      _selectedImage = null;
                    });
                    _removeProfilePhoto();
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

  Future<void> _removeProfilePhoto() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authController.firebaseUser.value?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firebaseService.firestore.collection('users').doc(userId).update({
        'profilePhotoUrl': null,
      });

      await _authController.loadUserData(userId);

      Get.snackbar(
        'Success',
        'Profile photo removed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.successColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ DEBUG [EditProfile]: Error removing photo: $e');
      Get.snackbar(
        'Error',
        'Failed to remove photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      final userId = _authController.firebaseUser.value?.uid;
      if (userId == null) throw Exception('User not logged in');

      print('📤 DEBUG [EditProfile]: Uploading image...');
      final fileName = 'profile_photos/$userId.jpg';
      final ref = _firebaseService.storage.ref().child(fileName);
      await ref.putFile(_selectedImage!);
      final url = await ref.getDownloadURL();

      print('✅ DEBUG [EditProfile]: Image uploaded: $url');
      return url;
    } catch (e) {
      print('❌ DEBUG [EditProfile]: Error uploading image: $e');
      Get.snackbar(
        'Error',
        'Failed to upload image. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authController.firebaseUser.value?.uid;
      if (userId == null) throw Exception('User not logged in');

      print('💾 DEBUG [EditProfile]: Saving profile...');

      // Upload image if selected
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _uploadImage();
        if (photoUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Update user data
      final updates = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'displayName': _displayNameController.text.trim(),
        'major': _majorController.text.trim(),
        'gender': _selectedGender,
      };

      if (photoUrl != null) {
        updates['profilePhotoUrl'] = photoUrl;
      }

      await _firebaseService.firestore.collection('users').doc(userId).update(updates);

      // Reload user data
      await _authController.loadUserData(userId);

      print('✅ DEBUG [EditProfile]: Profile saved successfully');

      Get.snackbar(
        'Success! 🎉',
        'Your profile has been updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.successColor.withOpacity(0.9),
        colorText: Colors.white,
      );

      Get.back(); // Return to settings
    } catch (e) {
      print('❌ DEBUG [EditProfile]: Error saving profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.userModel.value;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.primaryColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : user?.profilePhotoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: user!.profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppConstants.systemGray6,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => _buildDefaultAvatar(),
                                )
                              : _buildDefaultAvatar(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _showImageSourceDialog,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  if (_isUploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),

              // Personal Information
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PERSONAL INFORMATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CommonTextFormField(
                controller: _firstNameController,
                labelText: 'First Name',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CommonTextFormField(
                controller: _lastNameController,
                labelText: 'Last Name',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              CommonTextFormField(
                controller: _displayNameController,
                labelText: 'Display Name',
                prefixIcon: const Icon(Icons.badge_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a display name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.wc),
                  filled: true,
                  fillColor: AppConstants.systemGray6,
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
                    borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                  ),
                ),
                items: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(gender),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Academic Information
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACADEMIC INFORMATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CommonTextFormField(
                controller: _majorController,
                labelText: 'Major',
                prefixIcon: const Icon(Icons.school_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your major';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Read-Only Information
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACCOUNT INFORMATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildReadOnlyField(
                label: 'Email',
                value: user?.email ?? '',
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 16),

              _buildReadOnlyField(
                label: 'University',
                value: user?.universityId.toUpperCase() ?? '',
                icon: Icons.location_city_outlined,
              ),

              const SizedBox(height: 32),

              // Save Button
              IOSButton(
                text: 'Save Changes',
                onPressed: _isLoading ? null : _saveProfile,
                icon: Icons.check_circle_outline,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    final user = _authController.userModel.value;
    final initial = user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : '?';

    return Container(
      color: AppConstants.primaryColor.withOpacity(0.1),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(color: AppConstants.systemGray4),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: AppConstants.textSecondary),
        ],
      ),
    );
  }
}
