import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI Service for product valuation and negotiation coaching using Gemini API
/// Integrated with Keerthi's Firebase Cloud Function
class AIService {
  // ⚠️ UPDATED: Base URL changed from ProductPricePredictionApi to BarterBrainAPI
  static const String _baseUrl = 
      'https://us-central1-barterbrain-1254a.cloudfunctions.net/BarterBrainAPI';
  
  static const String _pricePredictionUrl = '$_baseUrl/ai/metadataValuation';
  static const String _negotiationCoachUrl = '$_baseUrl/ai/negotiationCoach';
  static const String _sustainabilityUrl = '$_baseUrl/swaps/confirm';
  
  /// Get AI-powered price suggestion for a product
  /// 
  /// Returns a map with:
  /// - value: double (suggested price)
  /// - confidence: double (0.0 to 1.0)
  /// - explanation: String
  /// - breakdown: Map<String, dynamic>
  /// 
  /// Required: At least title OR description
  /// Optional: category, condition, ageMonths, brand, accessories, images, productLink
  Future<Map<String, dynamic>> getPriceSuggestion({
    String? title,
    String? description,
    String? category,
    String? condition,
    int? ageMonths,
    String? brand,
    List<String>? accessories,
    List<String>? images,
    String? productLink,
  }) async {
    print('🤖 DEBUG: Calling Keerthi\'s Gemini AI API for price suggestion...');
    print('📦 DEBUG: Product: ${title ?? description}');
    print('🏷️  DEBUG: Brand: $brand, Age: $ageMonths months, Condition: $condition');
    
    // Validate: need at least title or description
    if ((title == null || title.isEmpty) && 
        (description == null || description.isEmpty)) {
      throw ArgumentError('Must provide either title or description');
    }

    try {
      final url = Uri.parse(_pricePredictionUrl);
      
      // Build request body - only include non-null values
      final Map<String, dynamic> requestBody = {};
      if (title != null && title.isNotEmpty) requestBody['title'] = title;
      if (description != null && description.isNotEmpty) requestBody['description'] = description;
      if (category != null && category.isNotEmpty) requestBody['category'] = category;
      if (condition != null && condition.isNotEmpty) requestBody['condition'] = condition;
      if (ageMonths != null) requestBody['ageMonths'] = ageMonths;
      if (brand != null && brand.isNotEmpty) requestBody['brand'] = brand;
      if (accessories != null && accessories.isNotEmpty) requestBody['accessories'] = accessories;
      if (images != null && images.isNotEmpty) requestBody['images'] = images.take(3).toList(); // Max 3 images
      if (productLink != null && productLink.isNotEmpty) requestBody['productLink'] = productLink;

      print('🌐 DEBUG: Sending request to: $url');
      print('📤 DEBUG: Request body: ${jsonEncode(requestBody)}');
      print('⏱️  DEBUG: API call started (this may take 6-14 seconds)...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60), // Keerthi's API can take 6-14 seconds
        onTimeout: () {
          throw Exception('Request timeout. The AI is taking longer than expected. Please try again.');
        },
      );

      print('📥 DEBUG: Response status: ${response.statusCode}');
      print('📥 DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ DEBUG: AI suggestion received successfully');
        print('💰 DEBUG: Suggested price: \$${data['value']}');
        print('🎯 DEBUG: Confidence: ${data['confidence']}');
        
        return data;
      } else if (response.statusCode == 404) {
        print('❌ DEBUG: API endpoint not found');
        throw Exception('AI service not available. Please contact support.');
      } else {
        print('❌ DEBUG: API error: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to get price suggestion');
      }
    } catch (e) {
      print('❌ DEBUG: Error calling AI API: $e');
      
      if (e.toString().contains('timeout')) {
        throw Exception('Request took too long. Please try again.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('No internet connection. Please check your network.');
      }
      
      rethrow;
    }
  }

  /// Parse accessories from product details
  List<String> parseAccessories(String description) {
    final accessories = <String>[];
    final lowerDesc = description.toLowerCase();

    // Common accessories keywords
    final accessoryKeywords = [
      'lock',
      'rack',
      'charger',
      'case',
      'cover',
      'bag',
      'box',
      'manual',
      'cable',
      'adapter',
      'warranty',
      'receipt',
    ];

    for (final keyword in accessoryKeywords) {
      if (lowerDesc.contains(keyword)) {
        accessories.add(keyword);
      }
    }

    print('🔍 DEBUG: Parsed accessories: $accessories');
    return accessories;
  }

  /// Get confidence level description
  String getConfidenceDescription(double confidence) {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.7) return 'Good';
    if (confidence >= 0.6) return 'Moderate';
    return 'Low';
  }

  /// Get confidence color
  String getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return '#4CAF50'; // Green
    if (confidence >= 0.6) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  /// Get AI-powered negotiation coaching
  /// 
  /// Helps users during chat negotiations by suggesting:
  /// - Smart message suggestions
  /// - Recommended cash adjustments
  /// - Negotiation strategy tips
  /// 
  /// Takes 6-15 seconds - show loading indicator!
  Future<NegotiationSuggestion> getNegotiationCoachSuggestion({
    required List<ChatMessageAI> chatTranscript,
    required ItemInfoAI userItem,
    required ItemInfoAI otherUserItem,
    OfferInfoAI? currentOffer,
  }) async {
    print('🤖 DEBUG: Calling Negotiation Coach AI...');
    
    // Validation
    if (chatTranscript.isEmpty) {
      throw ArgumentError('Chat transcript cannot be empty');
    }

    try {
      final url = Uri.parse(_negotiationCoachUrl);
      
      // Build request body
      final Map<String, dynamic> requestBody = {
        'chatTranscript': chatTranscript.map((msg) => {
          'message': msg.message,
          'isCurrentUser': msg.isCurrentUser,
        }).toList(),
        'userItem': {
          'title': userItem.title,
          if (userItem.description != null) 'description': userItem.description,
          if (userItem.estimatedValue != null) 'estimatedValue': userItem.estimatedValue,
          if (userItem.condition != null) 'condition': userItem.condition,
        },
        'otherUserItem': {
          'title': otherUserItem.title,
          if (otherUserItem.description != null) 'description': otherUserItem.description,
          if (otherUserItem.estimatedValue != null) 'estimatedValue': otherUserItem.estimatedValue,
          if (otherUserItem.condition != null) 'condition': otherUserItem.condition,
        },
        if (currentOffer != null) 'currentOffer': {
          if (currentOffer.cashAdjustment != null) 'cashAdjustment': currentOffer.cashAdjustment,
          if (currentOffer.status != null) 'status': currentOffer.status,
        }
      };

      print('🌐 DEBUG: Sending request to: $url');
      print('📤 DEBUG: Chat messages: ${chatTranscript.length}');
      print('📦 DEBUG: Your item: ${userItem.title}, Their item: ${otherUserItem.title}');
      print('⏱️  DEBUG: API call started (this may take 6-15 seconds)...');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout - please try again');
        },
      );

      print('📥 DEBUG: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ DEBUG: AI suggestion received successfully');
        print('💬 DEBUG: Suggestion: ${data['suggestionPhrase']}');
        print('💰 DEBUG: Cash adjustment: \$${data['suggestedCashAdjustment']}');
        
        return NegotiationSuggestion.fromJson(data);
      } else {
        print('❌ DEBUG: API error: ${response.body}');
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to get negotiation suggestion');
      }
    } catch (e) {
      print('❌ DEBUG: Error calling Negotiation Coach: $e');
      
      if (e.toString().contains('timeout')) {
        throw Exception('Request took too long. Please try again.');
      } else if (e.toString().contains('SocketException') || e.toString().contains('connection')) {
        throw Exception('No internet connection. Please check your network.');
      }
      
      rethrow;
    }
  }

  /// Get sustainability impact after trade completion
  /// 
  /// Calculates and returns environmental and financial savings
  /// from swapping instead of buying new.
  /// 
  /// Returns a message like: "You saved about 85 kg CO₂ and $60 by swapping instead of buying new."
  Future<String?> getSustainabilityImpact({
    required String tradeId,
    required double estimatedNewCost,
    required double proposerItemValue,
    required double proposerCash,
    required String itemName,
  }) async {
    print('🌱 DEBUG: Calling Sustainability Impact AI...');
    print('📦 DEBUG: Trade ID: $tradeId');
    print('🏷️  DEBUG: Item: $itemName, New cost: \$${estimatedNewCost.toStringAsFixed(2)}');
    
    try {
      final url = Uri.parse(_sustainabilityUrl);
      
      // Build request body (don't pass swapId to avoid document update attempt)
      final Map<String, dynamic> requestBody = {
        'swap': {
          'estimatedNewCost': estimatedNewCost,
          'proposerItemValue': proposerItemValue,
          'proposerCash': proposerCash,
          'itemName': itemName,
        }
      };

      print('🌐 DEBUG: Sending request to: $url');
      print('📤 DEBUG: Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please try again');
        },
      );

      print('📥 DEBUG: Response status: ${response.statusCode}');
      print('📥 DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (data['success'] == true) {
          final impact = data['sustainabilityImpact'] as String?;
          
          if (impact != null) {
            print('✅ DEBUG: Sustainability impact calculated: $impact');
          } else {
            print('⚠️  DEBUG: No sustainability impact calculated (missing data)');
          }
          
          return impact;
        } else {
          print('❌ DEBUG: API returned success=false');
          return null;
        }
      } else {
        print('❌ DEBUG: API error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ DEBUG: Error calling Sustainability API: $e');
      
      // Don't throw - sustainability is optional, return null on error
      return null;
    }
  }
}

/// Model for negotiation suggestion response
class NegotiationSuggestion {
  final String suggestionPhrase;
  final double suggestedCashAdjustment;
  final String explanation;
  final List<String> negotiationTips;

  NegotiationSuggestion({
    required this.suggestionPhrase,
    required this.suggestedCashAdjustment,
    required this.explanation,
    required this.negotiationTips,
  });

  factory NegotiationSuggestion.fromJson(Map<String, dynamic> json) {
    return NegotiationSuggestion(
      suggestionPhrase: json['suggestionPhrase'] as String,
      suggestedCashAdjustment: (json['suggestedCashAdjustment'] as num).toDouble(),
      explanation: json['explanation'] as String,
      negotiationTips: (json['negotiationTips'] as List).map((e) => e.toString()).toList(),
    );
  }

  String get formattedCashAdjustment {
    if (suggestedCashAdjustment == 0) return 'Even swap';
    final abs = suggestedCashAdjustment.abs();
    if (suggestedCashAdjustment > 0) {
      return 'You pay \$${abs.toStringAsFixed(2)}';
    } else {
      return 'You receive \$${abs.toStringAsFixed(2)}';
    }
  }
}

/// Model for chat message in AI request
class ChatMessageAI {
  final String message;
  final bool isCurrentUser;
  
  ChatMessageAI({required this.message, required this.isCurrentUser});
}

/// Model for item information in AI request
class ItemInfoAI {
  final String title;
  final String? description;
  final double? estimatedValue;
  final String? condition;
  
  ItemInfoAI({
    required this.title,
    this.description,
    this.estimatedValue,
    this.condition,
  });
}

/// Model for current offer information in AI request
class OfferInfoAI {
  final double? cashAdjustment;
  final String? status;
  
  OfferInfoAI({this.cashAdjustment, this.status});
}

