import 'package:cloud_firestore/cloud_firestore.dart';

/// Trade model for managing product exchanges between users
class TradeModel {
  final String id;
  final String chatId; // Associated chat
  final String initiatorUserId; // User who started the trade
  final String recipientUserId; // User who received the trade request
  
  // Products involved
  final List<String> initiatorProductIds; // Products from initiator
  final List<String> recipientProductIds; // Products from recipient
  
  // Trade details
  final double initiatorTotalValue; // Total value of initiator's products
  final double recipientTotalValue; // Total value of recipient's products
  final double priceDifference; // Absolute difference
  final String? payingUserId; // Who needs to pay (if any)
  final double? paymentAmount; // Amount to be paid
  
  // Payment details
  final String paymentType; // 'none', 'now', 'at_exchange'
  final bool isPaid; // Payment completed
  final String? nessieTransferId; // Nessie API transfer ID
  
  // Negotiation flow
  final String negotiationStatus; // 'negotiating', 'awaiting_confirmation', 'awaiting_payment', 'completed'
  final String? completionRequestedBy; // User ID who requested completion
  final double? agreedAmount; // Amount both parties agreed on (for payment requests)
  
  // Trade status
  final String status; // 'active', 'completed', 'cancelled'
  final bool initiatorConfirmed; // Initiator clicked green tick
  final bool recipientConfirmed; // Recipient clicked green tick
  
  // Sustainability
  final String? sustainabilityImpact; // AI-generated sustainability message
  
  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  TradeModel({
    required this.id,
    required this.chatId,
    required this.initiatorUserId,
    required this.recipientUserId,
    required this.initiatorProductIds,
    required this.recipientProductIds,
    required this.initiatorTotalValue,
    required this.recipientTotalValue,
    required this.priceDifference,
    this.payingUserId,
    this.paymentAmount,
    this.paymentType = 'none',
    this.isPaid = false,
    this.nessieTransferId,
    this.negotiationStatus = 'negotiating',
    this.completionRequestedBy,
    this.agreedAmount,
    this.status = 'active',
    this.initiatorConfirmed = false,
    this.recipientConfirmed = false,
    this.sustainabilityImpact,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Create TradeModel from Firestore document
  factory TradeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TradeModel(
      id: doc.id,
      chatId: data['chatId'] as String,
      initiatorUserId: data['initiatorUserId'] as String,
      recipientUserId: data['recipientUserId'] as String,
      initiatorProductIds: List<String>.from(data['initiatorProductIds'] as List),
      recipientProductIds: List<String>.from(data['recipientProductIds'] as List),
      initiatorTotalValue: (data['initiatorTotalValue'] as num).toDouble(),
      recipientTotalValue: (data['recipientTotalValue'] as num).toDouble(),
      priceDifference: (data['priceDifference'] as num).toDouble(),
      payingUserId: data['payingUserId'] as String?,
      paymentAmount: data['paymentAmount'] != null ? (data['paymentAmount'] as num).toDouble() : null,
      paymentType: data['paymentType'] as String? ?? 'none',
      isPaid: data['isPaid'] as bool? ?? false,
      nessieTransferId: data['nessieTransferId'] as String?,
      negotiationStatus: data['negotiationStatus'] as String? ?? 'negotiating',
      completionRequestedBy: data['completionRequestedBy'] as String?,
      agreedAmount: data['agreedAmount'] != null ? (data['agreedAmount'] as num).toDouble() : null,
      status: data['status'] as String? ?? 'active',
      initiatorConfirmed: data['initiatorConfirmed'] as bool? ?? false,
      recipientConfirmed: data['recipientConfirmed'] as bool? ?? false,
      sustainabilityImpact: data['sustainabilityImpact'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
    );
  }

  /// Convert TradeModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'initiatorUserId': initiatorUserId,
      'recipientUserId': recipientUserId,
      'initiatorProductIds': initiatorProductIds,
      'recipientProductIds': recipientProductIds,
      'initiatorTotalValue': initiatorTotalValue,
      'recipientTotalValue': recipientTotalValue,
      'priceDifference': priceDifference,
      'payingUserId': payingUserId,
      'paymentAmount': paymentAmount,
      'paymentType': paymentType,
      'isPaid': isPaid,
      'nessieTransferId': nessieTransferId,
      'negotiationStatus': negotiationStatus,
      'completionRequestedBy': completionRequestedBy,
      'agreedAmount': agreedAmount,
      'status': status,
      'initiatorConfirmed': initiatorConfirmed,
      'recipientConfirmed': recipientConfirmed,
      'sustainabilityImpact': sustainabilityImpact,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Create a copy with updated fields
  TradeModel copyWith({
    String? id,
    String? chatId,
    String? initiatorUserId,
    String? recipientUserId,
    List<String>? initiatorProductIds,
    List<String>? recipientProductIds,
    double? initiatorTotalValue,
    double? recipientTotalValue,
    double? priceDifference,
    String? payingUserId,
    double? paymentAmount,
    String? paymentType,
    bool? isPaid,
    String? nessieTransferId,
    String? negotiationStatus,
    String? completionRequestedBy,
    double? agreedAmount,
    String? status,
    bool? initiatorConfirmed,
    bool? recipientConfirmed,
    String? sustainabilityImpact,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TradeModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      initiatorUserId: initiatorUserId ?? this.initiatorUserId,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      initiatorProductIds: initiatorProductIds ?? this.initiatorProductIds,
      recipientProductIds: recipientProductIds ?? this.recipientProductIds,
      initiatorTotalValue: initiatorTotalValue ?? this.initiatorTotalValue,
      recipientTotalValue: recipientTotalValue ?? this.recipientTotalValue,
      priceDifference: priceDifference ?? this.priceDifference,
      payingUserId: payingUserId ?? this.payingUserId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentType: paymentType ?? this.paymentType,
      isPaid: isPaid ?? this.isPaid,
      nessieTransferId: nessieTransferId ?? this.nessieTransferId,
      negotiationStatus: negotiationStatus ?? this.negotiationStatus,
      completionRequestedBy: completionRequestedBy ?? this.completionRequestedBy,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      status: status ?? this.status,
      initiatorConfirmed: initiatorConfirmed ?? this.initiatorConfirmed,
      recipientConfirmed: recipientConfirmed ?? this.recipientConfirmed,
      sustainabilityImpact: sustainabilityImpact ?? this.sustainabilityImpact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Check if both users have confirmed the trade
  bool get isBothConfirmed => initiatorConfirmed && recipientConfirmed;

  /// Check if trade is completed
  bool get isCompleted => status == 'completed';

  /// Check if trade is active
  bool get isActive => status == 'active';

  /// Check if trade is cancelled
  bool get isCancelled => status == 'cancelled';
  
  /// Check if negotiation is in progress
  bool get isNegotiating => negotiationStatus == 'negotiating';
  
  /// Check if awaiting other user's confirmation
  bool get isAwaitingConfirmation => negotiationStatus == 'awaiting_confirmation';
  
  /// Check if awaiting payment
  bool get isAwaitingPayment => negotiationStatus == 'awaiting_payment';
  
  /// Check if other user needs to confirm completion request
  bool hasCompletionRequestFrom(String userId) => completionRequestedBy == userId;
  
  /// Check if payment is required (price difference exists)
  bool get requiresPayment => payingUserId != null && (paymentAmount ?? 0) > 0;
}

