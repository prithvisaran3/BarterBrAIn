import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat model for managing conversations between users
class ChatModel {
  final String id;
  final List<String> participantIds; // [userId1, userId2]
  final Map<String, String> participantNames; // {userId: displayName}
  final Map<String, String?> participantPhotos; // {userId: photoUrl}
  
  // Last message info for preview
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final String lastMessageType; // 'text', 'image', 'system'
  
  // Unread count per user
  final Map<String, int> unreadCount; // {userId: count}
  
  // Chat status
  final String status; // 'active', 'ended'
  final String? endedBy; // User who ended the chat
  final String? endReason; // 'not_interested', 'trade_completed'
  
  // Associated trade
  final String? tradeId;
  
  // Product details for AI (stores full product info)
  final Map<String, dynamic>? initiatorProducts; // {productId: {name, price, details, condition, imageUrls}}
  final Map<String, dynamic>? recipientProducts; // {productId: {name, price, details, condition, imageUrls}}
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    this.lastMessageType = 'text',
    required this.unreadCount,
    this.status = 'active',
    this.endedBy,
    this.endReason,
    this.tradeId,
    this.initiatorProducts,
    this.recipientProducts,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ChatModel from Firestore document
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] as List),
      participantNames: Map<String, String>.from(data['participantNames'] as Map),
      participantPhotos: Map<String, String?>.from(data['participantPhotos'] as Map),
      lastMessage: data['lastMessage'] as String?,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageTime: data['lastMessageTime'] != null 
          ? (data['lastMessageTime'] as Timestamp).toDate() 
          : null,
      lastMessageType: data['lastMessageType'] as String? ?? 'text',
      unreadCount: Map<String, int>.from(data['unreadCount'] as Map),
      status: data['status'] as String? ?? 'active',
      endedBy: data['endedBy'] as String?,
      endReason: data['endReason'] as String?,
      tradeId: data['tradeId'] as String?,
      initiatorProducts: data['initiatorProducts'] != null 
          ? Map<String, dynamic>.from(data['initiatorProducts'] as Map)
          : null,
      recipientProducts: data['recipientProducts'] != null 
          ? Map<String, dynamic>.from(data['recipientProducts'] as Map)
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert ChatModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageType': lastMessageType,
      'unreadCount': unreadCount,
      'status': status,
      'endedBy': endedBy,
      'endReason': endReason,
      'tradeId': tradeId,
      'initiatorProducts': initiatorProducts,
      'recipientProducts': recipientProducts,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  ChatModel copyWith({
    String? id,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    String? lastMessageType,
    Map<String, int>? unreadCount,
    String? status,
    String? endedBy,
    String? endReason,
    String? tradeId,
    Map<String, dynamic>? initiatorProducts,
    Map<String, dynamic>? recipientProducts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      status: status ?? this.status,
      endedBy: endedBy ?? this.endedBy,
      endReason: endReason ?? this.endReason,
      tradeId: tradeId ?? this.tradeId,
      initiatorProducts: initiatorProducts ?? this.initiatorProducts,
      recipientProducts: recipientProducts ?? this.recipientProducts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId);
  }

  /// Get the other participant's name
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown User';
  }

  /// Get the other participant's photo
  String? getOtherParticipantPhoto(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantPhotos[otherId];
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Check if chat is active
  bool get isActive => status == 'active';

  /// Check if chat is ended
  bool get isEnded => status == 'ended';
}

