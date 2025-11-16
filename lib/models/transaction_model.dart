import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction model for storing payment details
class TransactionModel {
  final String id;
  final String tradeId;
  final String payerUserId;
  final String payeeUserId;
  final double amount;
  final String paymentMethod; // 'nessie', 'pay_at_exchange', 'direct_swap'
  final String status; // 'pending', 'processing', 'completed', 'failed'
  final String? nessieTransferId;
  final String? nessieCustomerId;
  final String? nessieAccountId;
  final String description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  
  // Additional details for display
  final String? payerName;
  final String? payeeName;
  final String? payerPhoto;
  final String? payeePhoto;

  TransactionModel({
    required this.id,
    required this.tradeId,
    required this.payerUserId,
    required this.payeeUserId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.nessieTransferId,
    this.nessieCustomerId,
    this.nessieAccountId,
    required this.description,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.payerName,
    this.payeeName,
    this.payerPhoto,
    this.payeePhoto,
  });

  /// Create from Firestore document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      tradeId: data['tradeId'] ?? '',
      payerUserId: data['payerUserId'] ?? '',
      payeeUserId: data['payeeUserId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? 'direct_swap',
      status: data['status'] ?? 'pending',
      nessieTransferId: data['nessieTransferId'],
      nessieCustomerId: data['nessieCustomerId'],
      nessieAccountId: data['nessieAccountId'],
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      errorMessage: data['errorMessage'],
      payerName: data['payerName'],
      payeeName: data['payeeName'],
      payerPhoto: data['payerPhoto'],
      payeePhoto: data['payeePhoto'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'tradeId': tradeId,
      'payerUserId': payerUserId,
      'payeeUserId': payeeUserId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'nessieTransferId': nessieTransferId,
      'nessieCustomerId': nessieCustomerId,
      'nessieAccountId': nessieAccountId,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'errorMessage': errorMessage,
      'payerName': payerName,
      'payeeName': payeeName,
      'payerPhoto': payerPhoto,
      'payeePhoto': payeePhoto,
    };
  }

  /// Create a copy with updated fields
  TransactionModel copyWith({
    String? id,
    String? tradeId,
    String? payerUserId,
    String? payeeUserId,
    double? amount,
    String? paymentMethod,
    String? status,
    String? nessieTransferId,
    String? nessieCustomerId,
    String? nessieAccountId,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    String? payerName,
    String? payeeName,
    String? payerPhoto,
    String? payeePhoto,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      payerUserId: payerUserId ?? this.payerUserId,
      payeeUserId: payeeUserId ?? this.payeeUserId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      nessieTransferId: nessieTransferId ?? this.nessieTransferId,
      nessieCustomerId: nessieCustomerId ?? this.nessieCustomerId,
      nessieAccountId: nessieAccountId ?? this.nessieAccountId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      payerName: payerName ?? this.payerName,
      payeeName: payeeName ?? this.payeeName,
      payerPhoto: payerPhoto ?? this.payerPhoto,
      payeePhoto: payeePhoto ?? this.payeePhoto,
    );
  }

  /// Check if transaction is completed
  bool get isCompleted => status == 'completed';

  /// Check if transaction is pending
  bool get isPending => status == 'pending';

  /// Check if transaction failed
  bool get isFailed => status == 'failed';

  /// Get display status
  String get displayStatus {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'processing':
        return 'Processing';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  /// Get payment method display text
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'nessie':
        return 'Capital One (Nessie)';
      case 'pay_at_exchange':
        return 'Pay at Exchange';
      case 'direct_swap':
        return 'Direct Swap (No Payment)';
      default:
        return paymentMethod;
    }
  }
}

