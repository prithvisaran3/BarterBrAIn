import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/transaction_model.dart';
import 'firebase_service.dart';

/// Service for managing payment transactions
class TransactionService extends GetxService {
  final _firebaseService = Get.find<FirebaseService>();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Create a new transaction
  Future<TransactionModel> createTransaction({
    required String tradeId,
    required String payerUserId,
    required String payeeUserId,
    required double amount,
    required String paymentMethod,
    required String description,
    String? payerName,
    String? payeeName,
    String? payerPhoto,
    String? payeePhoto,
  }) async {
    print('💳 DEBUG [Transaction]: Creating transaction');
    print('💳 DEBUG [Transaction]: Payer: $payerUserId → Payee: $payeeUserId');
    print('💳 DEBUG [Transaction]: Amount: \$${amount.toStringAsFixed(2)}');
    print('💳 DEBUG [Transaction]: Method: $paymentMethod');

    try {
      final transactionData = {
        'tradeId': tradeId,
        'payerUserId': payerUserId,
        'payeeUserId': payeeUserId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'payerName': payerName,
        'payeeName': payeeName,
        'payerPhoto': payerPhoto,
        'payeePhoto': payeePhoto,
      };

      final docRef = await _firestore.collection('transactions').add(transactionData);

      print('✅ DEBUG [Transaction]: Transaction created: ${docRef.id}');

      return TransactionModel(
        id: docRef.id,
        tradeId: tradeId,
        payerUserId: payerUserId,
        payeeUserId: payeeUserId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: 'pending',
        description: description,
        createdAt: DateTime.now(),
        payerName: payerName,
        payeeName: payeeName,
        payerPhoto: payerPhoto,
        payeePhoto: payeePhoto,
      );
    } catch (e) {
      print('❌ ERROR [Transaction]: Failed to create transaction: $e');
      rethrow;
    }
  }

  /// Update transaction status
  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    String? nessieTransferId,
    String? errorMessage,
  }) async {
    print('💳 DEBUG [Transaction]: Updating transaction $transactionId to $status');

    try {
      final updateData = <String, dynamic>{
        'status': status,
      };

      if (status == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      if (nessieTransferId != null) {
        updateData['nessieTransferId'] = nessieTransferId;
      }

      if (errorMessage != null) {
        updateData['errorMessage'] = errorMessage;
      }

      await _firestore.collection('transactions').doc(transactionId).update(updateData);

      print('✅ DEBUG [Transaction]: Transaction updated successfully');
    } catch (e) {
      print('❌ ERROR [Transaction]: Failed to update transaction: $e');
      rethrow;
    }
  }

  /// Get transaction by ID
  Future<TransactionModel?> getTransaction(String transactionId) async {
    print('💳 DEBUG [Transaction]: Fetching transaction: $transactionId');

    try {
      final doc = await _firestore.collection('transactions').doc(transactionId).get();

      if (!doc.exists) {
        print('⚠️ DEBUG [Transaction]: Transaction not found');
        return null;
      }

      return TransactionModel.fromFirestore(doc);
    } catch (e) {
      print('❌ ERROR [Transaction]: Failed to fetch transaction: $e');
      return null;
    }
  }

  /// Get transactions for a user
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    print('💳 DEBUG [Transaction]: Streaming transactions for user: $userId');

    // Query 1: Where user is payer
    final query1 = _firestore
        .collection('transactions')
        .where('payerUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50);

    // Query 2: Where user is payee
    final query2 = _firestore
        .collection('transactions')
        .where('payeeUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50);

    // Combine both streams with error handling
    return query1.snapshots().handleError((error) {
      print('❌ ERROR [Transaction Query 1]: $error');
    }).asyncExpand((snapshot1) {
      return query2.snapshots().handleError((error) {
        print('❌ ERROR [Transaction Query 2]: $error');
      }).map((snapshot2) {
        try {
          print('💳 DEBUG [Transaction]: Query 1 returned ${snapshot1.docs.length} docs');
          print('💳 DEBUG [Transaction]: Query 2 returned ${snapshot2.docs.length} docs');
          
          final transactions1 = snapshot1.docs.map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              print('❌ ERROR [Transaction]: Error parsing transaction ${doc.id}: $e');
              return null;
            }
          }).whereType<TransactionModel>().toList();
          
          final transactions2 = snapshot2.docs.map((doc) {
            try {
              return TransactionModel.fromFirestore(doc);
            } catch (e) {
              print('❌ ERROR [Transaction]: Error parsing transaction ${doc.id}: $e');
              return null;
            }
          }).whereType<TransactionModel>().toList();

          // Combine and deduplicate
          final allTransactions = [...transactions1, ...transactions2];
          final uniqueTransactions = <String, TransactionModel>{};
          for (var transaction in allTransactions) {
            uniqueTransactions[transaction.id] = transaction;
          }

          // Sort by createdAt
          final sortedTransactions = uniqueTransactions.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          print('💳 DEBUG [Transaction]: Successfully combined to ${sortedTransactions.length} transactions');
          return sortedTransactions;
        } catch (e, stackTrace) {
          print('❌ ERROR [Transaction]: Error combining transactions: $e');
          print('❌ ERROR [Transaction]: Stack trace: $stackTrace');
          return <TransactionModel>[];
        }
      });
    });
  }

  /// Get transactions for a specific trade
  Future<List<TransactionModel>> getTradeTransactions(String tradeId) async {
    print('💳 DEBUG [Transaction]: Fetching transactions for trade: $tradeId');

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('tradeId', isEqualTo: tradeId)
          .orderBy('createdAt', descending: false)
          .get();

      print('💳 DEBUG [Transaction]: Found ${snapshot.docs.length} transactions');
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ ERROR [Transaction]: Failed to fetch trade transactions: $e');
      return [];
    }
  }

  /// Get transaction statistics for a user
  Future<Map<String, dynamic>> getUserTransactionStats(String userId) async {
    print('💳 DEBUG [Transaction]: Calculating transaction stats for user: $userId');

    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where(Filter.or(
            Filter('payerUserId', isEqualTo: userId),
            Filter('payeeUserId', isEqualTo: userId),
          ))
          .get();

      double totalPaid = 0;
      double totalReceived = 0;
      int completedCount = 0;
      int pendingCount = 0;
      int failedCount = 0;

      for (final doc in snapshot.docs) {
        final transaction = TransactionModel.fromFirestore(doc);

        if (transaction.payerUserId == userId) {
          totalPaid += transaction.amount;
        } else {
          totalReceived += transaction.amount;
        }

        switch (transaction.status) {
          case 'completed':
            completedCount++;
            break;
          case 'pending':
            pendingCount++;
            break;
          case 'failed':
            failedCount++;
            break;
        }
      }

      final stats = {
        'totalPaid': totalPaid,
        'totalReceived': totalReceived,
        'netBalance': totalReceived - totalPaid,
        'totalTransactions': snapshot.docs.length,
        'completedCount': completedCount,
        'pendingCount': pendingCount,
        'failedCount': failedCount,
      };

      print('✅ DEBUG [Transaction]: Stats calculated: $stats');
      return stats;
    } catch (e) {
      print('❌ ERROR [Transaction]: Failed to calculate stats: $e');
      return {
        'totalPaid': 0.0,
        'totalReceived': 0.0,
        'netBalance': 0.0,
        'totalTransactions': 0,
        'completedCount': 0,
        'pendingCount': 0,
        'failedCount': 0,
      };
    }
  }

  /// Delete a transaction (admin only - for testing)
  Future<void> deleteTransaction(String transactionId) async {
    print('💳 DEBUG [Transaction]: Deleting transaction: $transactionId');

    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
      print('✅ DEBUG [Transaction]: Transaction deleted');
    } catch (e) {
      print('❌ ERROR [Transaction]: Failed to delete transaction: $e');
      rethrow;
    }
  }
}

