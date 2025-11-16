import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

/// Service for managing chats and messages
class ChatService extends GetxService {
  final _firebaseService = Get.find<FirebaseService>();
  final _notificationService = Get.find<NotificationService>();

  FirebaseFirestore get _firestore => _firebaseService.firestore;
  FirebaseStorage get _storage => _firebaseService.storage;

  /// Create a new chat between two users
  Future<ChatModel> createChat({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserPhoto,
    required String otherUserId,
    required String otherUserName,
    required String? otherUserPhoto,
    String? tradeId,
    Map<String, dynamic>? initiatorProducts,
    Map<String, dynamic>? recipientProducts,
  }) async {
    print('💬 DEBUG: Creating chat between $currentUserId and $otherUserId');

    try {
      // Check if chat already exists
      final existingChat = await getChatBetweenUsers(currentUserId, otherUserId);
      if (existingChat != null) {
        print('✅ DEBUG: Chat already exists: ${existingChat.id}');
        
        // Update with product details if provided and not already set
        if ((initiatorProducts != null || recipientProducts != null) &&
            (existingChat.initiatorProducts == null || existingChat.recipientProducts == null)) {
          await _firestore.collection('chats').doc(existingChat.id).update({
            if (initiatorProducts != null) 'initiatorProducts': initiatorProducts,
            if (recipientProducts != null) 'recipientProducts': recipientProducts,
          });
          print('✅ DEBUG: Updated chat with product details');
        }
        
        return existingChat;
      }

      final now = DateTime.now();
      final chat = ChatModel(
        id: '', // Will be set by Firestore
        participantIds: [currentUserId, otherUserId],
        participantNames: {
          currentUserId: currentUserName,
          otherUserId: otherUserName,
        },
        participantPhotos: {
          currentUserId: currentUserPhoto,
          otherUserId: otherUserPhoto,
        },
        unreadCount: {
          currentUserId: 0,
          otherUserId: 0,
        },
        tradeId: tradeId,
        initiatorProducts: initiatorProducts,
        recipientProducts: recipientProducts,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection('chats').add(chat.toFirestore());
      print('✅ DEBUG: Chat created with ID: ${docRef.id}');
      if (initiatorProducts != null || recipientProducts != null) {
        print('✅ DEBUG: Chat includes product details for AI');
      }

      // Send notification to other user
      await _notificationService.sendNotification(
        userId: otherUserId,
        type: 'chat_started',
        title: 'New Chat',
        body: '$currentUserName started a chat with you',
        chatId: docRef.id,
        senderId: currentUserId,
        senderName: currentUserName,
        senderPhotoUrl: currentUserPhoto,
      );

      return chat.copyWith(id: docRef.id);
    } catch (e) {
      print('❌ DEBUG: Error creating chat: $e');
      rethrow;
    }
  }

  /// Get chat between two users
  Future<ChatModel?> getChatBetweenUsers(String userId1, String userId2) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId1)
          .get();

      for (var doc in querySnapshot.docs) {
        final chat = ChatModel.fromFirestore(doc);
        if (chat.participantIds.contains(userId2)) {
          return chat;
        }
      }

      return null;
    } catch (e) {
      print('❌ DEBUG: Error getting chat: $e');
      return null;
    }
  }

  /// Stream of user's chats
  /// ⚡ OPTIMIZED: Limited to 50 most recent chats for performance
  Stream<List<ChatModel>> getUserChats(String userId) {
    print('💬 DEBUG: Streaming chats for user: $userId');
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(50) // ⚡ PERFORMANCE: Only load 50 most recent chats
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  /// Stream of messages in a chat
  /// ⚡ OPTIMIZED: Limited to 200 most recent messages for performance
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    print('💬 DEBUG: Streaming messages for chat: $chatId');
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200) // ⚡ PERFORMANCE: Only load 200 most recent messages
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  /// Send text message
  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String? senderPhotoUrl,
    required String text,
    required String recipientId,
  }) async {
    print('💬 DEBUG: Sending text message to chat: $chatId');

    try {
      final now = DateTime.now();
      final message = MessageModel(
        id: '', // Will be set by Firestore
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: 'text',
        text: text,
        createdAt: now,
      );

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat's last message info
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageSenderId': senderId,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageType': 'text',
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });

      print('✅ DEBUG: Text message sent successfully');

      // Send notification to recipient
      await _notificationService.sendNotification(
        userId: recipientId,
        type: 'new_message',
        title: senderName,
        body: text,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
      );
    } catch (e) {
      print('❌ DEBUG: Error sending text message: $e');
      rethrow;
    }
  }

  /// Send image message
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String? senderPhotoUrl,
    required File imageFile,
    required String recipientId,
  }) async {
    print('💬 DEBUG: Sending image message to chat: $chatId');

    try {
      // Upload image to Firebase Storage
      final fileName = 'chats/$chatId/${DateTime.now().millisecondsSinceEpoch}_${senderId}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      print('✅ DEBUG: Image uploaded: $imageUrl');

      final now = DateTime.now();
      final message = MessageModel(
        id: '', // Will be set by Firestore
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        type: 'image',
        imageUrl: imageUrl,
        createdAt: now,
      );

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      // Update chat's last message info
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '📷 Photo',
        'lastMessageSenderId': senderId,
        'lastMessageTime': Timestamp.fromDate(now),
        'lastMessageType': 'image',
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });

      print('✅ DEBUG: Image message sent successfully');

      // Send notification
      await _notificationService.sendNotification(
        userId: recipientId,
        type: 'new_message',
        title: senderName,
        body: '📷 Sent a photo',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
      );
    } catch (e) {
      print('❌ DEBUG: Error sending image message: $e');
      rethrow;
    }
  }

  /// Send system message (e.g., "Trade completed")
  Future<void> sendSystemMessage({
    required String chatId,
    required String systemMessage,
  }) async {
    print('💬 DEBUG: Sending system message to chat: $chatId');

    try {
      final now = DateTime.now();
      final message = MessageModel(
        id: '', // Will be set by Firestore
        chatId: chatId,
        senderId: 'system',
        senderName: 'System',
        type: 'system',
        systemMessage: systemMessage,
        createdAt: now,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      print('✅ DEBUG: System message sent successfully');
    } catch (e) {
      print('❌ DEBUG: Error sending system message: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      // Reset unread count for this user
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      print('✅ DEBUG: Messages marked as read for user: $userId');
    } catch (e) {
      print('❌ DEBUG: Error marking messages as read: $e');
    }
  }

  /// End chat
  Future<void> endChat({
    required String chatId,
    required String endedBy,
    required String reason,
    required String otherUserId,
    required String currentUserName,
  }) async {
    print('💬 DEBUG: Ending chat: $chatId');

    try {
      await _firestore.collection('chats').doc(chatId).update({
        'status': 'ended',
        'endedBy': endedBy,
        'endReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Send system message
      await sendSystemMessage(
        chatId: chatId,
        systemMessage: reason == 'not_interested'
            ? 'Chat ended. No longer interested in trading.'
            : 'Trade completed successfully! 🎉',
      );

      // Send notification to other user
      await _notificationService.sendNotification(
        userId: otherUserId,
        type: 'chat_ended',
        title: 'Chat Ended',
        body: reason == 'not_interested'
            ? '$currentUserName is no longer interested in this trade'
            : 'Trade with $currentUserName completed!',
        chatId: chatId,
        senderId: endedBy,
      );

      print('✅ DEBUG: Chat ended successfully');
    } catch (e) {
      print('❌ DEBUG: Error ending chat: $e');
      rethrow;
    }
  }

  /// Get total unread message count for user
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      final chats = await _firestore
          .collection('chats')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'active')
          .get();

      int total = 0;
      for (var doc in chats.docs) {
        final chat = ChatModel.fromFirestore(doc);
        total += chat.getUnreadCount(userId);
      }

      return total;
    } catch (e) {
      print('❌ DEBUG: Error getting total unread count: $e');
      return 0;
    }
  }
}

