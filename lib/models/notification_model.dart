import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification model for in-app notifications
class NotificationModel {
  final String id;
  final String userId; // Recipient user ID
  final String type; // 'new_message', 'chat_started', 'chat_ended', 'trade_completed', 'payment_received'
  final String title;
  final String body;
  
  // Related entities
  final String? chatId;
  final String? tradeId;
  final String? senderId; // User who triggered the notification
  final String? senderName;
  final String? senderPhotoUrl;
  
  // Extra metadata (for custom data like payment amounts, etc.)
  final Map<String, dynamic>? data;
  
  // Notification status
  final bool isRead;
  final bool isClicked;
  
  // Timestamps
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.chatId,
    this.tradeId,
    this.senderId,
    this.senderName,
    this.senderPhotoUrl,
    this.data,
    this.isRead = false,
    this.isClicked = false,
    required this.createdAt,
  });

  /// Create NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final docData = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: docData['userId'] as String,
      type: docData['type'] as String,
      title: docData['title'] as String,
      body: docData['body'] as String,
      chatId: docData['chatId'] as String?,
      tradeId: docData['tradeId'] as String?,
      senderId: docData['senderId'] as String?,
      senderName: docData['senderName'] as String?,
      senderPhotoUrl: docData['senderPhotoUrl'] as String?,
      data: docData['data'] as Map<String, dynamic>?,
      isRead: docData['isRead'] as bool? ?? false,
      isClicked: docData['isClicked'] as bool? ?? false,
      createdAt: (docData['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert NotificationModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'chatId': chatId,
      'tradeId': tradeId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'data': data,
      'isRead': isRead,
      'isClicked': isClicked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? chatId,
    String? tradeId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isClicked,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      chatId: chatId ?? this.chatId,
      tradeId: tradeId ?? this.tradeId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isClicked: isClicked ?? this.isClicked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get icon for notification type
  String getIcon() {
    switch (type) {
      case 'new_message':
        return '💬';
      case 'chat_started':
        return '👋';
      case 'chat_ended':
        return '🔚';
      case 'trade_completed':
        return '✅';
      case 'payment_received':
        return '💰';
      default:
        return '📢';
    }
  }

  /// Get time ago string
  String getTimeAgo() {
    final difference = DateTime.now().difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

