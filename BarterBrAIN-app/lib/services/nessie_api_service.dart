import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'firebase_service.dart';

/// Service for Capital One Nessie API integration
class NessieAPIService extends GetxService {
  final _firebaseService = Get.find<FirebaseService>();

  // Capital One Nessie API Key
  static const String _apiKey = '5569f4a3e58bdd6f71a210a35e0a3334';
  static const String _baseUrl = 'http://api.nessieisreal.com';

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Create a Nessie customer account for a new user
  Future<String?> createCustomerAccount({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    print('💳 DEBUG: Creating Nessie customer account for user: $userId');

    if (_apiKey == 'YOUR_NESSIE_API_KEY_HERE') {
      print('⚠️ DEBUG: Nessie API key not configured - using mock account');
      // Create mock customer ID
      final mockCustomerId = 'mock_${userId.substring(0, 8)}';
      
      // Store in Firestore
      await _firestore.collection('users').doc(userId).update({
        'nessieCustomerId': mockCustomerId,
      });
      
      return mockCustomerId;
    }

    try {
      final url = Uri.parse('$_baseUrl/customers?key=$_apiKey');
      
      final requestBody = {
        'first_name': firstName,
        'last_name': lastName,
        'address': {
          'street_number': '123',
          'street_name': 'Campus Drive',
          'city': 'Palo Alto',
          'state': 'CA',
          'zip': '94301',
        },
      };

      print('🌐 DEBUG: Sending request to Nessie API');
      print('📤 DEBUG: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 DEBUG: Response status: ${response.statusCode}');
      print('📥 DEBUG: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final customerId = data['objectCreated']['_id'] as String;

        // Store customer ID in Firestore
        await _firestore.collection('users').doc(userId).update({
          'nessieCustomerId': customerId,
        });

        print('✅ DEBUG: Nessie customer created: $customerId');
        return customerId;
      } else {
        print('❌ DEBUG: Failed to create Nessie customer: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ DEBUG: Error creating Nessie customer: $e');
      return null;
    }
  }

  /// Create a bank account for a customer
  Future<String?> createBankAccount(String customerId) async {
    print('💳 DEBUG: Creating bank account for customer: $customerId');

    if (_apiKey == 'YOUR_NESSIE_API_KEY_HERE' || customerId.startsWith('mock_')) {
      print('⚠️ DEBUG: Using mock bank account');
      return 'mock_account_$customerId';
    }

    try {
      final url = Uri.parse('$_baseUrl/customers/$customerId/accounts?key=$_apiKey');
      
      final requestBody = {
        'type': 'Checking',
        'nickname': 'BarterBrAIn Trading Account',
        'rewards': 0,
        'balance': 1000, // Starting balance
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 DEBUG: Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accountId = data['objectCreated']['_id'] as String;

        print('✅ DEBUG: Bank account created: $accountId');
        return accountId;
      } else {
        print('❌ DEBUG: Failed to create bank account: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ DEBUG: Error creating bank account: $e');
      return null;
    }
  }

  /// Make a payment from one user to another
  Future<Map<String, dynamic>> makePayment({
    required String payerUserId,
    required String payeeUserId,
    required double amount,
    required String description,
  }) async {
    print('💰 DEBUG: Processing payment: \$$amount from $payerUserId to $payeeUserId');

    try {
      // Get payer's Nessie account info
      final payerDoc = await _firestore.collection('users').doc(payerUserId).get();
      final payerData = payerDoc.data()!;
      final payerAccountId = payerData['nessieAccountId'] as String?;

      if (payerAccountId == null) {
        // Create account if doesn't exist
        final payerCustomerId = payerData['nessieCustomerId'] as String?;
        if (payerCustomerId == null) {
          throw Exception('Payer does not have a Nessie customer account');
        }
        
        final newAccountId = await createBankAccount(payerCustomerId);
        if (newAccountId == null) {
          throw Exception('Failed to create bank account for payer');
        }
        
        await _firestore.collection('users').doc(payerUserId).update({
          'nessieAccountId': newAccountId,
        });
      }

      // Get payee's Nessie account info
      final payeeDoc = await _firestore.collection('users').doc(payeeUserId).get();
      final payeeData = payeeDoc.data()!;
      final payeeAccountId = payeeData['nessieAccountId'] as String?;

      if (payeeAccountId == null) {
        // Create account if doesn't exist
        final payeeCustomerId = payeeData['nessieCustomerId'] as String?;
        if (payeeCustomerId == null) {
          throw Exception('Payee does not have a Nessie customer account');
        }
        
        final newAccountId = await createBankAccount(payeeCustomerId);
        if (newAccountId == null) {
          throw Exception('Failed to create bank account for payee');
        }
        
        await _firestore.collection('users').doc(payeeUserId).update({
          'nessieAccountId': newAccountId,
        });
      }

      // Check if using mock accounts
      final payerAccountIdFinal = payerData['nessieAccountId'] as String? ?? 
                                   (await _firestore.collection('users').doc(payerUserId).get()).data()!['nessieAccountId'];
      final payeeAccountIdFinal = payeeData['nessieAccountId'] as String? ?? 
                                   (await _firestore.collection('users').doc(payeeUserId).get()).data()!['nessieAccountId'];

      if (_apiKey == 'YOUR_NESSIE_API_KEY_HERE' || 
          payerAccountIdFinal!.startsWith('mock_')) {
        print('⚠️ DEBUG: Using mock payment');
        
        // Return mock success
        return {
          'success': true,
          'transferId': 'mock_transfer_${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Mock payment processed successfully',
        };
      }

      // Make actual API call to transfer money
      final url = Uri.parse('$_baseUrl/accounts/$payerAccountIdFinal/transfers?key=$_apiKey');
      
      final requestBody = {
        'medium': 'balance',
        'payee_id': payeeAccountIdFinal,
        'amount': amount,
        'transaction_date': DateTime.now().toIso8601String(),
        'description': description,
      };

      print('🌐 DEBUG: Sending transfer request to Nessie API');
      print('📤 DEBUG: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 DEBUG: Response status: ${response.statusCode}');
      print('📥 DEBUG: Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final transferId = data['objectCreated']['_id'] as String;

        print('✅ DEBUG: Payment successful: $transferId');
        
        return {
          'success': true,
          'transferId': transferId,
          'message': 'Payment processed successfully',
        };
      } else {
        print('❌ DEBUG: Payment failed: ${response.body}');
        
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Payment failed',
        };
      }
    } catch (e) {
      print('❌ DEBUG: Error processing payment: $e');
      
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get customer's account balance
  Future<double?> getAccountBalance(String userId) async {
    print('💰 DEBUG: Getting account balance for user: $userId');

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final accountId = userDoc.data()?['nessieAccountId'] as String?;

      if (accountId == null) {
        print('⚠️ DEBUG: User does not have a bank account');
        return null;
      }

      if (_apiKey == 'YOUR_NESSIE_API_KEY_HERE' || accountId.startsWith('mock_')) {
        print('⚠️ DEBUG: Returning mock balance');
        return 1000.0; // Mock balance
      }

      final url = Uri.parse('$_baseUrl/accounts/$accountId?key=$_apiKey');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final balance = (data['balance'] as num).toDouble();

        print('✅ DEBUG: Account balance: \$$balance');
        return balance;
      } else {
        print('❌ DEBUG: Failed to get balance: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ DEBUG: Error getting balance: $e');
      return null;
    }
  }

  /// Check if API key is configured
  bool get isConfigured => _apiKey != 'YOUR_NESSIE_API_KEY_HERE';
}

