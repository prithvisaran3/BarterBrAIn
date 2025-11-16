import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/nessie_api_service.dart';
import '../core/constants.dart';

/// Controller for authentication flows
class AuthController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  late final NessieAPIService _nessieService;

  // Observable state
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> userModel = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  // Signup flow state
  String? _pendingEmail;
  String? _pendingUniversityId;
  String? _pendingPassword;

  bool get isAuthenticated => firebaseUser.value != null;

  @override
  void onInit() {
    super.onInit();
    _nessieService = Get.find<NessieAPIService>();
    // Listen to auth state changes
    firebaseUser.bindStream(_firebaseService.authStateChanges);
    ever(firebaseUser, _onAuthStateChanged);
  }

  /// Handle auth state changes
  Future<void> _onAuthStateChanged(User? user) async {
    print('🔧 DEBUG: Auth state changed. User: ${user?.email ?? "null"}');
    if (user != null) {
      print('🔧 DEBUG: User authenticated, loading data...');
      // Load user data from Firestore
      await loadUserData(user.uid);
    } else {
      print('🔧 DEBUG: User signed out, clearing data...');
      userModel.value = null;
    }
  }

  /// Load user data from Firestore
  Future<void> loadUserData(String uid) async {
    try {
      print('🔧 DEBUG: loadUserData called for UID: $uid');
      final doc = await _firebaseService.usersCollection.doc(uid).get();
      print('🔧 DEBUG: Firestore document exists: ${doc.exists}');
      
      if (doc.exists) {
        print('🔧 DEBUG: Document data: ${doc.data()}');
        userModel.value = UserModel.fromFirestore(doc);
        print('✅ DEBUG: User model loaded successfully: ${userModel.value?.displayName}');
        
        // Ensure Nessie account exists for payments
        await _ensureNessieAccount();
      } else {
        print('⚠️  DEBUG: User document does not exist in Firestore');
        userModel.value = null;
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error loading user data: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      userModel.value = null;
    }
  }
  
  /// Ensure user has a Nessie account for payments
  Future<void> _ensureNessieAccount() async {
    try {
      final user = userModel.value;
      if (user == null) return;
      
      // Check if user already has Nessie customer ID
      if (user.nessieCustomerId != null && user.nessieCustomerId!.isNotEmpty) {
        print('✅ DEBUG: User already has Nessie account: ${user.nessieCustomerId}');
        return;
      }
      
      print('💳 DEBUG: Creating Nessie account for user: ${user.uid}');
      
      // Create Nessie customer account
      final customerId = await _nessieService.createCustomerAccount(
        userId: user.uid,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
      );
      
      if (customerId != null) {
        print('✅ DEBUG: Nessie customer created: $customerId');
        
        // Create bank account
        final accountId = await _nessieService.createBankAccount(customerId);
        
        if (accountId != null) {
          print('✅ DEBUG: Nessie bank account created: $accountId');
          
          // Update user model
          userModel.value = user.copyWith(
            nessieCustomerId: customerId,
            nessieAccountId: accountId,
          );
          
          print('✅ DEBUG: Nessie account setup complete for ${user.displayName}');
        } else {
          print('⚠️  DEBUG: Failed to create Nessie bank account');
        }
      } else {
        print('⚠️  DEBUG: Failed to create Nessie customer');
      }
    } catch (e) {
      print('❌ DEBUG: Error ensuring Nessie account: $e');
      // Don't throw - this is not critical for app functionality
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      
      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        Get.snackbar(
          'Success',
          'Welcome back!',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        AppConstants.errorGeneric,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Send OTP to email via Cloud Function
  Future<bool> sendOtp(String email, String universityId) async {
    try {
      isLoading.value = true;
      
      print('📧 DEBUG: Sending OTP to $email for university: $universityId');

      // Validate .edu domain (allow any .edu email)
      if (!email.toLowerCase().endsWith('.edu')) {
        print('❌ DEBUG: Email is not a .edu address');
        Get.snackbar(
          'Invalid Email',
          'Please use a valid .edu email address.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Store pending signup data
      _pendingEmail = email;
      _pendingUniversityId = universityId;
      
      print('✅ DEBUG: Email validated, calling Cloud Function...');

      // Call Cloud Function to send OTP
      final result = await _firebaseService.callFunction('sendOtp', {
        'email': email,
        'universityId': universityId,
      });

      print('✅ DEBUG: Cloud Function response: $result');

      if (result['success'] == true) {
        // Show OTP in debug mode for easy testing
        if (result.containsKey('otp')) {
          print('🔐 DEBUG: OTP for testing: ${result['otp']}');
        }
        
        Get.snackbar(
          'OTP Sent',
          'Check your email for the verification code. (Dev mode: Check console)',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return true;
      } else {
        print('❌ DEBUG: OTP send failed: ${result['message']}');
        Get.snackbar(
          'Error',
          result['message'] ?? AppConstants.errorGeneric,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      print('❌ DEBUG: Error sending OTP: $e');
      Get.snackbar(
        'Error',
        'Failed to send OTP. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify OTP via Cloud Function
  Future<bool> verifyOtp(String otp, String password) async {
    try {
      isLoading.value = true;

      if (_pendingEmail == null) {
        Get.snackbar(
          'Error',
          'Session expired. Please start signup again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Store password for later
      _pendingPassword = password;

      // Call Cloud Function to verify OTP
      final result = await _firebaseService.callFunction('verifyOtp', {
        'email': _pendingEmail,
        'otp': otp,
      });

      if (result['success'] == true) {
        Get.snackbar(
          'Success',
          AppConstants.successOtpVerified,
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? AppConstants.errorInvalidOtp,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      Get.snackbar(
        'Error',
        'Failed to verify OTP. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete profile setup and create user account
  Future<bool> completeProfileSetup({
    required String firstName,
    required String lastName,
    required String gender,
    required String major,
    File? profilePhoto,
  }) async {
    try {
      print('🔧 DEBUG: Starting profile setup...');
      print('🔧 DEBUG: firstName=$firstName, lastName=$lastName, gender=$gender, major=$major');
      print('🔧 DEBUG: profilePhoto=${profilePhoto?.path}');
      
      isLoading.value = true;

      print('🔧 DEBUG: Checking pending data...');
      print('🔧 DEBUG: _pendingEmail=$_pendingEmail');
      print('🔧 DEBUG: _pendingPassword=${_pendingPassword != null ? "EXISTS (length: ${_pendingPassword!.length})" : "NULL"}');
      print('🔧 DEBUG: _pendingUniversityId=$_pendingUniversityId');

      if (_pendingEmail == null || _pendingPassword == null || _pendingUniversityId == null) {
        print('❌ DEBUG: Missing pending data!');
        Get.snackbar(
          'Error',
          'Session expired. Please start signup again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      print('🔧 DEBUG: Creating Firebase Auth account...');
      print('🔧 DEBUG: Email to use: $_pendingEmail');
      print('🔧 DEBUG: Password length: ${_pendingPassword!.length}');
      
      UserCredential? credential;
      try {
        // Create Firebase Auth account
        credential = await _firebaseService.auth.createUserWithEmailAndPassword(
          email: _pendingEmail!,
          password: _pendingPassword!,
        );
      } on FirebaseAuthException catch (e) {
        print('❌ DEBUG: FirebaseAuthException caught!');
        print('❌ DEBUG: Error code: ${e.code}');
        print('❌ DEBUG: Error message: ${e.message}');
        print('❌ DEBUG: Error plugin: ${e.plugin}');
        print('❌ DEBUG: Error stackTrace: ${e.stackTrace}');
        print('❌ DEBUG: Full error: $e');
        
        if (e.code == 'email-already-in-use') {
          print('⚠️  DEBUG: Email already in use, trying to sign in instead...');
          // Account already exists, try to sign in
          try {
            credential = await _firebaseService.auth.signInWithEmailAndPassword(
              email: _pendingEmail!,
              password: _pendingPassword!,
            );
            print('✅ DEBUG: Signed in to existing account');
          } catch (signInError) {
            print('❌ DEBUG: Could not sign in to existing account: $signInError');
            throw Exception('Account already exists but could not sign in. Please use login instead.');
          }
        } else if (e.code == 'weak-password') {
          print('❌ DEBUG: Password is too weak');
          throw Exception('Password is too weak. Please use at least 6 characters.');
        } else if (e.code == 'invalid-email') {
          print('❌ DEBUG: Invalid email format');
          throw Exception('Invalid email format.');
        } else if (e.code == 'internal-error') {
          print('❌ DEBUG: Internal error - this might be a password length issue or Firebase configuration issue');
          print('❌ DEBUG: Password length check - ensure password is at least 6 characters');
          throw Exception('Internal Firebase error. Please check password requirements (minimum 6 characters).');
        } else {
          print('❌ DEBUG: Unhandled auth error: ${e.code}');
          rethrow;
        }
      }

      if (credential.user == null) {
        print('❌ DEBUG: credential.user is null!');
        throw Exception('Failed to create user account');
      }

      final uid = credential.user!.uid;
      print('✅ DEBUG: Firebase Auth account created with UID: $uid');
      
      String? profilePhotoUrl;

      // Upload profile photo if provided
      if (profilePhoto != null) {
        print('🔧 DEBUG: Uploading profile photo...');
        try {
          profilePhotoUrl = await _uploadProfilePhoto(uid, profilePhoto);
          print('✅ DEBUG: Profile photo uploaded: $profilePhotoUrl');
        } catch (e) {
          print('⚠️  DEBUG: Photo upload failed (continuing without photo): $e');
          // Continue without photo - it's optional
        }
      } else {
        print('🔧 DEBUG: No profile photo provided, skipping upload');
      }

      print('🔧 DEBUG: Creating user document in Firestore...');
      // Create user document in Firestore
      final displayName = '$firstName $lastName';
      final userData = UserModel(
        uid: uid,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        email: _pendingEmail!,
        profilePhotoUrl: profilePhotoUrl,
        gender: gender,
        major: major,
        universityId: _pendingUniversityId!,
        isVerifiedEdu: true, // Set to true since OTP was verified
        createdAt: DateTime.now(),
      );

      print('🔧 DEBUG: User data model created:');
      print('🔧 DEBUG: ${userData.toFirestore()}');

      print('🔧 DEBUG: Checking if user document already exists...');
      final existingDoc = await _firebaseService.usersCollection.doc(uid).get();
      
      print('🔧 DEBUG: Writing to Firestore...');
      try {
        if (existingDoc.exists) {
          print('⚠️  DEBUG: User document already exists, updating instead...');
          await _firebaseService.usersCollection.doc(uid).update(userData.toFirestore());
          print('✅ DEBUG: Firestore document updated successfully');
        } else {
          print('🔧 DEBUG: Creating new user document...');
          await _firebaseService.usersCollection.doc(uid).set(userData.toFirestore());
          print('✅ DEBUG: Firestore document created successfully');
        }
      } catch (firestoreError) {
        print('❌ DEBUG: Firestore write error: $firestoreError');
        rethrow;
      }

      print('🔧 DEBUG: Updating Firebase Auth profile...');
      // Update Firebase Auth display name
      await credential.user!.updateDisplayName(displayName);
      if (profilePhotoUrl != null) {
        await credential.user!.updatePhotoURL(profilePhotoUrl);
      }
      print('✅ DEBUG: Firebase Auth profile updated');

      print('🔧 DEBUG: Loading user data from Firestore...');
      // Load user data into controller
      await loadUserData(uid);
      print('✅ DEBUG: User data loaded into controller');
      
      // Update the firebaseUser observable to trigger UI updates
      firebaseUser.value = credential.user;
      print('✅ DEBUG: Firebase user set in observable');

      // Clear pending data
      _pendingEmail = null;
      _pendingPassword = null;
      _pendingUniversityId = null;
      print('✅ DEBUG: Pending data cleared');

      print('🎉 DEBUG: Profile setup completed successfully!');
      Get.snackbar(
        'Success',
        AppConstants.successProfileCreated,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: FirebaseAuthException: ${e.code} - ${e.message}');
      _handleAuthError(e);
      return false;
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error completing profile setup: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to create profile. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
      print('🔧 DEBUG: isLoading set to false');
    }
  }

  /// Upload profile photo to Firebase Storage
  Future<String?> _uploadProfilePhoto(String uid, File file) async {
    try {
      final ref = _firebaseService.profilePhotosRef(uid).child('profile.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      
      // Sign out from Firebase
      await _firebaseService.auth.signOut();
      
      // Clear all user data
      firebaseUser.value = null;
      userModel.value = null;
      
      // Clear pending signup data
      _pendingEmail = null;
      _pendingPassword = null;
      _pendingUniversityId = null;
      
      // Clear GetStorage cache if needed
      final storage = GetStorage();
      await storage.erase();
      
      isLoading.value = false;
      
      // Show success message
      Get.snackbar(
        'Success',
        'You have been signed out successfully',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
      // Navigate to login and clear all routes
      Get.offAllNamed('/login');
    } catch (e) {
      isLoading.value = false;
      print('Error signing out: $e');
      Get.snackbar(
        'Error',
        'Failed to sign out. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
      Get.snackbar(
        'Success',
        'Password reset email sent!',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Handle Firebase Auth errors
  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Incorrect password.';
        break;
      case 'email-already-in-use':
        message = 'This email is already registered.';
        break;
      case 'invalid-email':
        message = 'Invalid email address.';
        break;
      case 'weak-password':
        message = 'Password is too weak.';
        break;
      case 'network-request-failed':
        message = AppConstants.errorNetwork;
        break;
      default:
        message = e.message ?? AppConstants.errorGeneric;
    }
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Getters for pending signup data
  String? get pendingEmail => _pendingEmail;
  String? get pendingUniversityId => _pendingUniversityId;
}

