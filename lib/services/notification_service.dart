import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../models/notification_model.dart';
import 'firebase_service.dart';

/// Service for managing in-app notifications
class NotificationService extends GetxService {
  final _firebaseService = Get.find<FirebaseService>();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  // Observable for unread notification count
  final unreadCount = 0.obs;

  /// Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    String? body,
    String? message,
    String? chatId,
    String? tradeId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    Map<String, dynamic>? data,
  }) async {
    print('🔔 DEBUG: Sending notification to user: $userId');

    try {
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        userId: userId,
        type: type,
        title: title,
        body: body ?? message ?? '',
        chatId: chatId,
        tradeId: tradeId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        data: data,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toFirestore());

      print('✅ DEBUG: Notification sent successfully');
    } catch (e) {
      print('❌ DEBUG: Error sending notification: $e');
    }
  }

  /// Stream of user's notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    print('🔔 DEBUG: Streaming notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      final notifications =
          snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
      
      // Update unread count
      unreadCount.value = notifications.where((n) => !n.isRead).length;
      
      return notifications;
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      print('✅ DEBUG: Notification marked as read');
    } catch (e) {
      print('❌ DEBUG: Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      print('✅ DEBUG: All notifications marked as read');
    } catch (e) {
      print('❌ DEBUG: Error marking all as read: $e');
    }
  }

  /// Mark notification as clicked
  Future<void> markAsClicked(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isClicked': true,
        'isRead': true,
      });

      print('✅ DEBUG: Notification marked as clicked');
    } catch (e) {
      print('❌ DEBUG: Error marking notification as clicked: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      print('✅ DEBUG: Notification deleted');
    } catch (e) {
      print('❌ DEBUG: Error deleting notification: $e');
    }
  }

  /// Delete all notifications for user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      print('✅ DEBUG: All notifications deleted');
    } catch (e) {
      print('❌ DEBUG: Error deleting all notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('❌ DEBUG: Error getting unread count: $e');
      return 0;
    }
  }
}

