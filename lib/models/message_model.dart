import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for chat messages
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  
  // Message content
  final String type; // 'text', 'image', 'system'
  final String? text; // For text messages
  final String? imageUrl; // For image messages
  final String? systemMessage; // For system messages (e.g., "Trade completed")
  
  // Message status
  final bool isRead;
  final List<String> readBy; // User IDs who have read this message
  
  // Timestamps
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.type,
    this.text,
    this.imageUrl,
    this.systemMessage,
    this.isRead = false,
    this.readBy = const [],
    required this.createdAt,
  });

  /// Create MessageModel from Firestore document
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      type: data['type'] as String,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      systemMessage: data['systemMessage'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      readBy: data['readBy'] != null ? List<String>.from(data['readBy'] as List) : [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert MessageModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'type': type,
      'text': text,
      'imageUrl': imageUrl,
      'systemMessage': systemMessage,
      'isRead': isRead,
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with updated fields
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? type,
    String? text,
    String? imageUrl,
    String? systemMessage,
    bool? isRead,
    List<String>? readBy,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      systemMessage: systemMessage ?? this.systemMessage,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Check if message is a text message
  bool get isTextMessage => type == 'text';

  /// Check if message is an image message
  bool get isImageMessage => type == 'image';

  /// Check if message is a system message
  bool get isSystemMessage => type == 'system';

  /// Get display content (for preview)
  String getDisplayContent() {
    if (isTextMessage && text != null) return text!;
    if (isImageMessage) return '📷 Photo';
    if (isSystemMessage && systemMessage != null) return systemMessage!;
    return '';
  }
}

