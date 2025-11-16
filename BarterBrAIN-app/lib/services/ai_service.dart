import 'dart:convert';
import 'package:http/http.dart' as http;

/// AI Service for product valuation using Gemini API
/// Integrated with Keerthi's Firebase Cloud Function
class AIService {
  // Keerthi's deployed Firebase Cloud Function endpoint
  static const String _apiUrl = 
      'https://us-central1-barterbrain-1254a.cloudfunctions.net/ProductPricePredictionApi/ai/metadataValuation';
  
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
      final url = Uri.parse(_apiUrl);
      
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
}

