import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/ios_button.dart';
import '../../core/constants.dart';

class SettingsView extends StatelessWidget {
  SettingsView({super.key});

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
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            Text(
              'ACCOUNT',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Edit Profile
            _buildSettingsItem(
              context,
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Update your profile information',
              onTap: () {
                Get.toNamed('/edit-profile');
              },
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Change Password
            _buildSettingsItem(
              context,
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your password',
              onTap: () {
                // TODO: Implement change password
                Get.snackbar(
                  'Coming Soon',
                  'Change password feature will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // Preferences Section
            Text(
              'PREFERENCES',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Notifications
            _buildSettingsItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () {
                // TODO: Implement notifications settings
                Get.snackbar(
                  'Coming Soon',
                  'Notification settings will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Privacy
            _buildSettingsItem(
              context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              subtitle: 'Manage privacy settings',
              onTap: () {
                // TODO: Implement privacy settings
                Get.snackbar(
                  'Coming Soon',
                  'Privacy settings will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // About Section
            Text(
              'ABOUT',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Help & Support
            _buildSettingsItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help or contact support',
              onTap: () {
                // TODO: Implement help & support
                Get.snackbar(
                  'Coming Soon',
                  'Help & support will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Terms of Service
            _buildSettingsItem(
              context,
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              subtitle: 'Read our terms and conditions',
              onTap: () {
                // TODO: Implement terms of service
                Get.snackbar(
                  'Coming Soon',
                  'Terms of service will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Privacy Policy
            _buildSettingsItem(
              context,
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              onTap: () {
                // TODO: Implement privacy policy
                Get.snackbar(
                  'Coming Soon',
                  'Privacy policy will be available soon',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // App Version
            Center(
              child: Text(
                'BarterBrAIn v1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingXl),
            
            // Sign Out Button
            Obx(() => IOSButton(
                  text: 'Sign Out',
                  onPressed: _authController.isLoading.value 
                      ? null 
                      : () => _showSignOutDialog(context),
                  isDestructive: true,
                  icon: Icons.logout,
                  isLoading: _authController.isLoading.value,
                )),
            
            const SizedBox(height: AppConstants.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: AppConstants.systemGray6,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Icon(
                  icon,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppConstants.systemGray2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? All cached data will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog first
              await _authController.signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}

