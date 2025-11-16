import 'package:cloud_firestore/cloud_firestore.dart';

/// Product model for items listed on the marketplace
class ProductModel {
  final String id;
  final String userId;
  final String name;
  final String details;
  final String brand;
  final int ageInMonths;
  final String? productLink;
  final String condition; // 'new', 'good', 'fair', 'bad'
  final double price; // Price set by user
  final double? aiSuggestedPrice; // AI-suggested price (optional)
  final String? aiExplanation; // AI explanation for the price
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  // Trade-related fields
  final bool isTraded; // Product has been traded
  final String? tradedWith; // User ID of person traded with
  final DateTime? tradedDate; // When the trade was completed
  final String? tradeId; // Associated trade ID

  ProductModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.details,
    required this.brand,
    required this.ageInMonths,
    this.productLink,
    required this.condition,
    required this.price,
    this.aiSuggestedPrice,
    this.aiExplanation,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isTraded = false,
    this.tradedWith,
    this.tradedDate,
    this.tradeId,
  });

  /// Create ProductModel from Firestore document
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      details: data['details'] as String,
      brand: data['brand'] as String,
      ageInMonths: data['ageInMonths'] as int,
      productLink: data['productLink'] as String?,
      condition: data['condition'] as String,
      price: (data['price'] as num).toDouble(),
      aiSuggestedPrice: data['aiSuggestedPrice'] != null ? (data['aiSuggestedPrice'] as num).toDouble() : null,
      aiExplanation: data['aiExplanation'] as String?,
      imageUrls: List<String>.from(data['imageUrls'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      isTraded: data['isTraded'] as bool? ?? false,
      tradedWith: data['tradedWith'] as String?,
      tradedDate: data['tradedDate'] != null ? (data['tradedDate'] as Timestamp).toDate() : null,
      tradeId: data['tradeId'] as String?,
    );
  }

  /// Convert ProductModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'details': details,
      'brand': brand,
      'ageInMonths': ageInMonths,
      'productLink': productLink,
      'condition': condition,
      'price': price,
      'aiSuggestedPrice': aiSuggestedPrice,
      'aiExplanation': aiExplanation,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'isTraded': isTraded,
      'tradedWith': tradedWith,
      'tradedDate': tradedDate != null ? Timestamp.fromDate(tradedDate!) : null,
      'tradeId': tradeId,
    };
  }

  /// Create a copy with updated fields
  ProductModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? details,
    String? brand,
    int? ageInMonths,
    String? productLink,
    String? condition,
    double? price,
    double? aiSuggestedPrice,
    String? aiExplanation,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isTraded,
    String? tradedWith,
    DateTime? tradedDate,
    String? tradeId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      details: details ?? this.details,
      brand: brand ?? this.brand,
      ageInMonths: ageInMonths ?? this.ageInMonths,
      productLink: productLink ?? this.productLink,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      aiSuggestedPrice: aiSuggestedPrice ?? this.aiSuggestedPrice,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isTraded: isTraded ?? this.isTraded,
      tradedWith: tradedWith ?? this.tradedWith,
      tradedDate: tradedDate ?? this.tradedDate,
      tradeId: tradeId ?? this.tradeId,
    );
  }
}

