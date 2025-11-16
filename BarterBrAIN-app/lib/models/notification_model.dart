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
    this.isRead = false,
    this.isClicked = false,
    required this.createdAt,
  });

  /// Create NotificationModel from Firestore document
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      body: data['body'] as String,
      chatId: data['chatId'] as String?,
      tradeId: data['tradeId'] as String?,
      senderId: data['senderId'] as String?,
      senderName: data['senderName'] as String?,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      isClicked: data['isClicked'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
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

