import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/trade_model.dart';
import '../models/product_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Service for managing trades between users
class TradeService extends GetxService {
  final _firebaseService = Get.find<FirebaseService>();
  final _notificationService = Get.find<NotificationService>();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Create a new trade
  Future<TradeModel> createTrade({
    required String chatId,
    required String initiatorUserId,
    required String recipientUserId,
    required List<String> initiatorProductIds,
    required List<String> recipientProductIds,
  }) async {
    print('🔄 DEBUG: Creating trade for chat: $chatId');

    try {
      // Calculate total values
      double initiatorTotal = 0;
      double recipientTotal = 0;

      // Get initiator products
      for (var productId in initiatorProductIds) {
        final doc = await _firestore.collection('products').doc(productId).get();
        if (doc.exists) {
          final product = ProductModel.fromFirestore(doc);
          initiatorTotal += product.price;
        }
      }

      // Get recipient products
      for (var productId in recipientProductIds) {
        final doc = await _firestore.collection('products').doc(productId).get();
        if (doc.exists) {
          final product = ProductModel.fromFirestore(doc);
          recipientTotal += product.price;
        }
      }

      final priceDifference = (initiatorTotal - recipientTotal).abs();
      String? payingUserId;
      double? paymentAmount;

      // Determine who needs to pay
      if (priceDifference > 0) {
        payingUserId = initiatorTotal > recipientTotal ? recipientUserId : initiatorUserId;
        paymentAmount = priceDifference;
      }

      print('💰 DEBUG: Initiator total: \$$initiatorTotal');
      print('💰 DEBUG: Recipient total: \$$recipientTotal');
      print('💰 DEBUG: Price difference: \$$priceDifference');
      print('💰 DEBUG: Paying user: ${payingUserId ?? "none"}');

      final now = DateTime.now();
      final trade = TradeModel(
        id: '', // Will be set by Firestore
        chatId: chatId,
        initiatorUserId: initiatorUserId,
        recipientUserId: recipientUserId,
        initiatorProductIds: initiatorProductIds,
        recipientProductIds: recipientProductIds,
        initiatorTotalValue: initiatorTotal,
        recipientTotalValue: recipientTotal,
        priceDifference: priceDifference,
        payingUserId: payingUserId,
        paymentAmount: paymentAmount,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection('trades').add(trade.toFirestore());
      print('✅ DEBUG: Trade created with ID: ${docRef.id}');

      // Update chat with tradeId
      await _firestore.collection('chats').doc(chatId).update({
        'tradeId': docRef.id,
      });

      return trade.copyWith(id: docRef.id);
    } catch (e) {
      print('❌ DEBUG: Error creating trade: $e');
      rethrow;
    }
  }

  /// Get trade by ID
  Future<TradeModel?> getTradeById(String tradeId) async {
    try {
      final doc = await _firestore.collection('trades').doc(tradeId).get();
      if (doc.exists) {
        return TradeModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ DEBUG: Error getting trade: $e');
      return null;
    }
  }

  /// Get trade by chat ID
  Future<TradeModel?> getTradeByChatId(String chatId, String userId) async {
    try {
      print('🔍 DEBUG: Getting trade by chat: $chatId for user: $userId');
      
      // First try as initiator
      var querySnapshot = await _firestore
          .collection('trades')
          .where('chatId', isEqualTo: chatId)
          .where('initiatorUserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('✅ DEBUG: Found trade as initiator');
        return TradeModel.fromFirestore(querySnapshot.docs.first);
      }

      // Then try as recipient
      querySnapshot = await _firestore
          .collection('trades')
          .where('chatId', isEqualTo: chatId)
          .where('recipientUserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('✅ DEBUG: Found trade as recipient');
        return TradeModel.fromFirestore(querySnapshot.docs.first);
      }

      print('ℹ️ DEBUG: No trade found for chat: $chatId');
      return null;
    } catch (e) {
      print('❌ DEBUG: Error getting trade by chat: $e');
      return null;
    }
  }

  /// Stream of user's trades
  Stream<List<TradeModel>> getUserTrades(String userId, {String? status}) {
    print('🔄 DEBUG: Streaming trades for user: $userId');
    
    Query query = _firestore.collection('trades');
    
    // Filter by user (either initiator or recipient)
    if (status != null) {
      return query
          .where('status', isEqualTo: status)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TradeModel.fromFirestore(doc))
            .where((trade) =>
                trade.initiatorUserId == userId || trade.recipientUserId == userId)
            .toList();
      });
    } else {
      return query
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TradeModel.fromFirestore(doc))
            .where((trade) =>
                trade.initiatorUserId == userId || trade.recipientUserId == userId)
            .toList();
      });
    }
  }

  /// Confirm trade (user clicks green tick)
  Future<void> confirmTrade({
    required String tradeId,
    required String userId,
    required String otherUserId,
    required String userName,
  }) async {
    print('✅ DEBUG: User $userId confirming trade: $tradeId');

    try {
      final trade = await getTradeById(tradeId);
      if (trade == null) {
        throw Exception('Trade not found');
      }

      final isInitiator = trade.initiatorUserId == userId;
      final updateData = {
        isInitiator ? 'initiatorConfirmed' : 'recipientConfirmed': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('trades').doc(tradeId).update(updateData);

      // Check if both confirmed
      final updatedTrade = await getTradeById(tradeId);
      if (updatedTrade!.isBothConfirmed) {
        print('🎉 DEBUG: Both users confirmed! Trade complete.');
        // Trade will be completed in the UI after payment handling
      } else {
        // Send notification to other user
        await _notificationService.sendNotification(
          userId: otherUserId,
          type: 'trade_confirmed',
          title: 'Trade Update',
          body: '$userName confirmed the trade',
          tradeId: tradeId,
          senderId: userId,
        );
      }

      print('✅ DEBUG: Trade confirmation updated');
    } catch (e) {
      print('❌ DEBUG: Error confirming trade: $e');
      rethrow;
    }
  }

  /// Update trade status (simple status update with products marked as traded)
  Future<void> updateTradeStatus({
    required String tradeId,
    required String status,
    DateTime? completedAt,
  }) async {
    print('🔄 DEBUG: Updating trade status: $tradeId to $status');

    try {
      final trade = await getTradeById(tradeId);
      if (trade == null) {
        throw Exception('Trade not found');
      }

      final now = DateTime.now();
      final Map<String, dynamic> updates = {
        'status': status,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (completedAt != null) {
        updates['completedAt'] = Timestamp.fromDate(completedAt);
      }

      // Update trade status
      await _firestore.collection('trades').doc(tradeId).update(updates);

      // If status is completed, mark products as traded
      if (status == 'completed') {
        // Mark all initiator products as traded
        for (var productId in trade.initiatorProductIds) {
          await _firestore.collection('products').doc(productId).update({
            'isTraded': true,
            'tradedWith': trade.recipientUserId,
            'tradedDate': Timestamp.fromDate(now),
            'tradeId': tradeId,
            'isActive': false,
          });
        }

        // Mark all recipient products as traded
        for (var productId in trade.recipientProductIds) {
          await _firestore.collection('products').doc(productId).update({
            'isTraded': true,
            'tradedWith': trade.initiatorUserId,
            'tradedDate': Timestamp.fromDate(now),
            'tradeId': tradeId,
            'isActive': false,
          });
        }

        // Send notifications to both users
        await _notificationService.sendNotification(
          userId: trade.initiatorUserId,
          type: 'trade_completed',
          title: 'Trade Completed! 🎉',
          body: 'Your trade has been completed successfully',
          tradeId: tradeId,
        );

        await _notificationService.sendNotification(
          userId: trade.recipientUserId,
          type: 'trade_completed',
          title: 'Trade Completed! 🎉',
          body: 'Your trade has been completed successfully',
          tradeId: tradeId,
        );
      }

      print('✅ DEBUG: Trade status updated to $status');
    } catch (e) {
      print('❌ DEBUG: Error updating trade status: $e');
      rethrow;
    }
  }

  /// Complete trade (mark products as traded)
  Future<void> completeTrade({
    required String tradeId,
    required String paymentType,
    bool isPaid = false,
    String? nessieTransferId,
  }) async {
    print('🎉 DEBUG: Completing trade: $tradeId');

    try {
      final trade = await getTradeById(tradeId);
      if (trade == null) {
        throw Exception('Trade not found');
      }

      final now = DateTime.now();

      // Update trade status
      await _firestore.collection('trades').doc(tradeId).update({
        'status': 'completed',
        'paymentType': paymentType,
        'isPaid': isPaid,
        'nessieTransferId': nessieTransferId,
        'completedAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Mark all initiator products as traded
      for (var productId in trade.initiatorProductIds) {
        await _firestore.collection('products').doc(productId).update({
          'isTraded': true,
          'tradedWith': trade.recipientUserId,
          'tradedDate': Timestamp.fromDate(now),
          'tradeId': tradeId,
          'isActive': false,
        });
      }

      // Mark all recipient products as traded
      for (var productId in trade.recipientProductIds) {
        await _firestore.collection('products').doc(productId).update({
          'isTraded': true,
          'tradedWith': trade.initiatorUserId,
          'tradedDate': Timestamp.fromDate(now),
          'tradeId': tradeId,
          'isActive': false,
        });
      }

      // Send notifications to both users
      await _notificationService.sendNotification(
        userId: trade.initiatorUserId,
        type: 'trade_completed',
        title: 'Trade Completed! 🎉',
        body: 'Your trade has been completed successfully',
        tradeId: tradeId,
      );

      await _notificationService.sendNotification(
        userId: trade.recipientUserId,
        type: 'trade_completed',
        title: 'Trade Completed! 🎉',
        body: 'Your trade has been completed successfully',
        tradeId: tradeId,
      );

      print('✅ DEBUG: Trade completed successfully');
    } catch (e) {
      print('❌ DEBUG: Error completing trade: $e');
      rethrow;
    }
  }

  /// Cancel trade
  Future<void> cancelTrade(String tradeId) async {
    print('❌ DEBUG: Cancelling trade: $tradeId');

    try {
      await _firestore.collection('trades').doc(tradeId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ DEBUG: Trade cancelled');
    } catch (e) {
      print('❌ DEBUG: Error cancelling trade: $e');
      rethrow;
    }
  }

  /// Update trade products
  Future<void> updateTradeProducts({
    required String tradeId,
    required String userId,
    required List<String> productIds,
  }) async {
    print('🔄 DEBUG: Updating trade products for user: $userId');

    try {
      final trade = await getTradeById(tradeId);
      if (trade == null) {
        throw Exception('Trade not found');
      }

      final isInitiator = trade.initiatorUserId == userId;

      // Recalculate totals
      double newTotal = 0;
      for (var productId in productIds) {
        final doc = await _firestore.collection('products').doc(productId).get();
        if (doc.exists) {
          final product = ProductModel.fromFirestore(doc);
          newTotal += product.price;
        }
      }

      final updateData = {
        isInitiator ? 'initiatorProductIds' : 'recipientProductIds': productIds,
        isInitiator ? 'initiatorTotalValue' : 'recipientTotalValue': newTotal,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('trades').doc(tradeId).update(updateData);

      // Recalculate price difference
      final updatedTrade = await getTradeById(tradeId);
      final priceDifference = (updatedTrade!.initiatorTotalValue - updatedTrade.recipientTotalValue).abs();
      String? payingUserId;
      double? paymentAmount;

      if (priceDifference > 0) {
        payingUserId = updatedTrade.initiatorTotalValue > updatedTrade.recipientTotalValue
            ? updatedTrade.recipientUserId
            : updatedTrade.initiatorUserId;
        paymentAmount = priceDifference;
      }

      await _firestore.collection('trades').doc(tradeId).update({
        'priceDifference': priceDifference,
        'payingUserId': payingUserId,
        'paymentAmount': paymentAmount,
      });

      print('✅ DEBUG: Trade products updated');
    } catch (e) {
      print('❌ DEBUG: Error updating trade products: $e');
      rethrow;
    }
  }

  /// Get trade statistics for user
  Future<Map<String, int>> getTradeStats(String userId) async {
    try {
      final completedTrades = await _firestore
          .collection('trades')
          .where('status', isEqualTo: 'completed')
          .get();

      final activeTrades = await _firestore
          .collection('trades')
          .where('status', isEqualTo: 'active')
          .get();

      int userCompleted = completedTrades.docs
          .map((doc) => TradeModel.fromFirestore(doc))
          .where((trade) =>
              trade.initiatorUserId == userId || trade.recipientUserId == userId)
          .length;

      int userActive = activeTrades.docs
          .map((doc) => TradeModel.fromFirestore(doc))
          .where((trade) =>
              trade.initiatorUserId == userId || trade.recipientUserId == userId)
          .length;

      return {
        'completed': userCompleted,
        'active': userActive,
      };
    } catch (e) {
      print('❌ DEBUG: Error getting trade stats: $e');
      return {'completed': 0, 'active': 0};
    }
  }
}

