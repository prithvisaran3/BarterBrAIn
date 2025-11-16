import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/university_service.dart';
import '../../core/constants.dart';

class ProfileView extends StatelessWidget {
  ProfileView({super.key});

  final _authController = Get.find<AuthController>();
  final _universityService = Get.find<UniversityService>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                  ),
                  label: const Text('Logout'),
                  onPressed: () => _handleLogout(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Obx(() {
              final user = _authController.userModel.value;
              
              print('🔧 DEBUG ProfileView: user is ${user == null ? "null" : "loaded"}');
              
              if (user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppConstants.spacingM),
                      Text(
                        'Loading profile...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                      ),
                    ],
                  ),
                );
              }
              
              final university = _universityService.getUniversityById(user.universityId);
              
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingL,
                  0,
                  AppConstants.spacingL,
                  100, // Space for nav bar
                ),
                child: Column(
            children: [
              // Profile Photo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.systemGray6,
                  image: user.profilePhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.profilePhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.profilePhotoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: AppConstants.systemGray2,
                      )
                    : null,
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Name
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              
              const SizedBox(height: AppConstants.spacingS),
              
              // Email with verified badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                  ),
                  if (user.isVerifiedEdu) ...[
                    const SizedBox(width: AppConstants.spacingS),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: AppConstants.primaryColor,
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Credit Balance Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.primaryColor.withOpacity(0.1),
                      AppConstants.secondaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Available Credits',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppConstants.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${user.creditBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Transaction History Button
              _buildActionButton(
                context,
                'Transaction History',
                'View your payment transactions',
                Icons.receipt_long_outlined,
                () => Get.toNamed('/transaction-history'),
              ),
              
              const SizedBox(height: AppConstants.spacingXl),
              
              // Info Cards
              _buildInfoCard(
                context,
                'University',
                university?.name ?? 'Unknown',
                Icons.school_outlined,
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              _buildInfoCard(
                context,
                'Major',
                user.major,
                Icons.book_outlined,
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              _buildInfoCard(
                context,
                'Gender',
                user.gender,
                Icons.person_outline,
              ),
              
              const SizedBox(height: AppConstants.spacingM),
            ],
          ),
        );
      }),
    ),
  ],
),
    );
  }
  
  void _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        // Show loading indicator
        Get.dialog(
          const Center(
            child: CircularProgressIndicator(),
          ),
          barrierDismissible: false,
        );
        
        // Sign out
        await _authController.signOut();
        
        // Close loading dialog
        Get.back();
        
        // Navigate to login
        Get.offAllNamed('/login');
        
        // Show success message
        Get.snackbar(
          'Success',
          'You have been logged out',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          margin: const EdgeInsets.all(AppConstants.spacingM),
          borderRadius: AppConstants.radiusM,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        // Close loading dialog if it's still open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        
        // Show error message
        Get.snackbar(
          'Error',
          'Failed to logout: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(AppConstants.spacingM),
          borderRadius: AppConstants.radiusM,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
  
  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppConstants.systemGray3.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Icon(
                    icon,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.tertiaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
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
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
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
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
