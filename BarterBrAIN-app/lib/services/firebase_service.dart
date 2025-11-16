import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

/// Centralized Firebase service wrapper
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Auth getters
  User? get currentUser => auth.currentUser;
  String? get currentUserId => auth.currentUser?.uid;
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Firestore collection references
  CollectionReference get usersCollection => firestore.collection(AppConstants.usersCollection);

  CollectionReference get universitiesCollection =>
      firestore.collection(AppConstants.universitiesCollection);

  CollectionReference get productsCollection =>
      firestore.collection(AppConstants.productsCollection);

  CollectionReference get chatsCollection => firestore.collection(AppConstants.chatsCollection);

  CollectionReference get emailOtpsCollection =>
      firestore.collection(AppConstants.emailOtpsCollection);

  CollectionReference get emailOtpsDebugCollection =>
      firestore.collection(AppConstants.emailOtpsDebugCollection);

  // Storage references
  Reference profilePhotosRef(String userId) =>
      storage.ref().child(AppConstants.profilePhotosPath).child(userId);

  Reference productImagesRef(String userId, String productId) =>
      storage.ref().child(AppConstants.productImagesPath).child(userId).child(productId);

  /// Initialize Firebase (called in main.dart)
  Future<void> initialize() async {
    // Configure Firebase emulator for local development
    // Uncomment these lines when using Firebase Emulator:

    // await auth.useAuthEmulator('localhost', 9099);
    // firestore.useFirestoreEmulator('localhost', 8080);
    // await storage.useStorageEmulator('localhost', 9199);
  }

  /// Call Cloud Function
  ///
  /// Tries deployed Cloud Functions first (production), falls back to development mode
  Future<dynamic> callFunction(String name, Map<String, dynamic>? data) async {
    // Try calling deployed Cloud Function first
    try {
      return await _callDeployedFunction(name, data);
    } catch (e) {
      print('⚠️  Cloud Function not available, using development mode: $e');

      // Fall back to development mode
      if (name == 'sendOtp') {
        return await _sendOtpDevelopment(data!['email'], data['universityId']);
      } else if (name == 'verifyOtp') {
        return await _verifyOtpDevelopment(data!['email'], data['otp']);
      }

      throw Exception('Unknown function: $name');
    }
  }

  /// Call deployed Cloud Function via HTTP
  Future<Map<String, dynamic>> _callDeployedFunction(
    String name,
    Map<String, dynamic>? data,
  ) async {
    const projectId = 'barterbrain-1254a';
    const region = 'us-central1'; // Default region, change if needed
    final url = 'https://$region-$projectId.cloudfunctions.net/$name';

    // Get current user's ID token for authentication
    final idToken = await auth.currentUser?.getIdToken();

    final headers = {
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };

    final response = await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({'data': data}),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Request timeout'),
        );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['result'] as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      throw Exception('Function not deployed');
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error']?['message'] ?? 'Function call failed');
    }
  }

  /// Development mode: Send OTP (stores in Firestore, no email)
  Future<Map<String, dynamic>> _sendOtpDevelopment(String email, String universityId) async {
    try {
      print('🔧 DEBUG: Development mode - sending OTP');

      // Validate email
      if (!email.contains('@') || !email.toLowerCase().endsWith('.edu')) {
        print('❌ DEBUG: Invalid email format');
        throw Exception('Invalid .edu email address');
      }

      print('✅ DEBUG: Email validation passed');

      // Check if university exists (optional, just for logging)
      final universityDoc = await firestore.collection('universities').doc(universityId).get();
      if (!universityDoc.exists) {
        print(
            '⚠️ DEBUG: University "$universityId" not in database - proceeding anyway for .edu verification');
      } else {
        print('✅ DEBUG: University "$universityId" found in database');
      }

      // Generate 6-digit OTP
      final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      print('🔐 DEBUG: Generated OTP: $otp');

      // Store in Firestore debug collection (development mode)
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));

      await firestore
          .collection(AppConstants.emailOtpsDebugCollection)
          .doc(email.toLowerCase())
          .set({
        'otp': otp,
        'email': email,
        'universityId': universityId,
        'expiresAt': expiresAt,
        'createdAt': DateTime.now(),
      });

      print('✅ DEBUG: OTP stored in Firestore emailOtpsDebug collection');
      print('🔐 DEV MODE - OTP for $email: $otp');
      print('⏰ DEBUG: OTP expires at: $expiresAt');

      return {
        'success': true,
        'message': 'OTP sent successfully',
        'debug': 'DEV MODE: Check console for OTP or Firestore emailOtpsDebug collection',
        'otp': otp, // Only in dev mode!
      };
    } catch (e) {
      print('❌ DEBUG: Failed to send OTP in dev mode: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Development mode: Verify OTP (checks Firestore)
  Future<Map<String, dynamic>> _verifyOtpDevelopment(String email, String otp) async {
    try {
      print('🔧 DEBUG: Development mode - verifying OTP');
      print('📧 DEBUG: Email: $email');
      print('🔐 DEBUG: OTP entered: $otp');

      // Validate OTP format
      if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        print('❌ DEBUG: Invalid OTP format (must be 6 digits)');
        throw Exception('Invalid OTP format');
      }

      print('✅ DEBUG: OTP format valid');

      // Get OTP from debug collection
      final otpDoc = await firestore
          .collection(AppConstants.emailOtpsDebugCollection)
          .doc(email.toLowerCase())
          .get();

      if (!otpDoc.exists) {
        print('❌ DEBUG: No OTP found in Firestore for email: $email');
        throw Exception('No OTP found for this email. Please request a new one.');
      }

      print('✅ DEBUG: OTP document found in Firestore');

      final otpData = otpDoc.data()!;
      final storedOtp = otpData['otp'] as String;
      final expiresAt = (otpData['expiresAt'] as Timestamp).toDate();

      print('🔐 DEBUG: Stored OTP: $storedOtp');
      print('⏰ DEBUG: Expires at: $expiresAt');
      print('⏰ DEBUG: Current time: ${DateTime.now()}');

      // Check expiry
      if (expiresAt.isBefore(DateTime.now())) {
        print('❌ DEBUG: OTP has expired');
        await otpDoc.reference.delete();
        throw Exception('OTP has expired. Please request a new one.');
      }

      print('✅ DEBUG: OTP not expired');

      // Check OTP match
      if (storedOtp != otp) {
        print('❌ DEBUG: OTP mismatch - entered: $otp, expected: $storedOtp');
        throw Exception('Invalid OTP. Please try again.');
      }

      print('✅ DEBUG: OTP match successful!');

      // OTP is valid - delete it
      await otpDoc.reference.delete();
      print('✅ DEBUG: OTP document deleted from Firestore');

      return {
        'success': true,
        'message': 'Email verified successfully',
      };
    } catch (e) {
      print('❌ DEBUG: Failed to verify OTP in dev mode: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }
}
