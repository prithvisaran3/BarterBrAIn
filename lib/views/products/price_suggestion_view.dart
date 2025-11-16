import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../services/firebase_service.dart';

class PriceSuggestionView extends StatefulWidget {
  final Map<String, dynamic>? aiSuggestion; // Now optional
  final String? aiErrorMessage; // Error message when AI fails
  final String productName;
  final String productDetails;
  final String brand;
  final int ageInMonths;
  final String condition;
  final String? productLink;
  final List<String> imageUrls;

  const PriceSuggestionView({
    super.key,
    this.aiSuggestion, // Optional
    this.aiErrorMessage, // Optional
    required this.productName,
    required this.productDetails,
    required this.brand,
    required this.ageInMonths,
    required this.condition,
    this.productLink,
    required this.imageUrls,
  });

  @override
  State<PriceSuggestionView> createState() => _PriceSuggestionViewState();
}

class _PriceSuggestionViewState extends State<PriceSuggestionView>
    with SingleTickerProviderStateMixin {
  final _priceController = TextEditingController();
  final _authController = Get.find<AuthController>();
  final _firebaseService = Get.find<FirebaseService>();

  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get hasAISuggestion => widget.aiSuggestion != null;
  double? get suggestedPrice => hasAISuggestion && widget.aiSuggestion!['value'] != null
      ? (widget.aiSuggestion!['value'] as num).toDouble()
      : null;
  double? get confidence => hasAISuggestion && widget.aiSuggestion!['confidence'] != null
      ? (widget.aiSuggestion!['confidence'] as num).toDouble()
      : null;
  String? get explanation => hasAISuggestion && widget.aiSuggestion!['explanation'] != null
      ? widget.aiSuggestion!['explanation'] as String
      : null;

  // Check if we have valid AI data to display
  bool get hasValidAISuggestion =>
      suggestedPrice != null && confidence != null && explanation != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill with AI suggestion if available
    if (hasAISuggestion && suggestedPrice != null) {
      _priceController.text = suggestedPrice!.toStringAsFixed(2);
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSetPrice(bool useAIPrice) async {
    print('💰 DEBUG: Setting product price...');

    final priceText = useAIPrice && suggestedPrice != null
        ? suggestedPrice!.toStringAsFixed(2)
        : _priceController.text.trim();

    // Validate price
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      Get.snackbar(
        'Invalid Price',
        'Please enter a valid price greater than 0',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    print('💰 DEBUG: Final price: \$$price');
    if (hasAISuggestion) {
      print('🤖 DEBUG: AI suggested: \$$suggestedPrice');
      print('👤 DEBUG: User chose: ${useAIPrice ? "AI suggestion" : "Custom price"}');
    } else {
      print('⚠️ DEBUG: No AI suggestion available - user set manual price');
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = _authController.firebaseUser.value!.uid;
      final now = DateTime.now();

      print('🚀 DEBUG: Creating product with price...');
      final product = ProductModel(
        id: '', // Will be set by Firestore
        userId: userId,
        name: widget.productName,
        details: widget.productDetails,
        brand: widget.brand,
        ageInMonths: widget.ageInMonths,
        productLink: widget.productLink,
        condition: widget.condition,
        price: price,
        aiSuggestedPrice: suggestedPrice, // Will be null if AI unavailable
        aiExplanation: explanation, // Will be null if AI unavailable
        imageUrls: widget.imageUrls,
        createdAt: now,
        updatedAt: now,
      );

      print('🚀 DEBUG: Saving product to Firestore...');
      final docRef =
          await _firebaseService.firestore.collection('products').add(product.toFirestore());

      print('✅ DEBUG: Product saved successfully with ID: ${docRef.id}');
      print('💰 DEBUG: Final price stored: \$${product.price}');

      Get.snackbar(
        'Success!',
        'Your product has been listed at \$${price.toStringAsFixed(2)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.successColor.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navigate to home view after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed('/main'); // Navigate to home and clear navigation stack
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error saving product: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');

      Get.snackbar(
        'Oops!',
        'Failed to list product. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Price Setup'),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AI Suggestion Card OR Error Card
                if (hasValidAISuggestion) _buildAISuggestionCard() else _buildAIUnavailableCard(),
                const SizedBox(height: AppConstants.spacingXl),

                // User Input Section
                _buildUserInputSection(),
                const SizedBox(height: AppConstants.spacingXl),

                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAIUnavailableCard() {
    // Check if AI provided an explanation even without a price
    final hasAIExplanation = explanation != null && explanation!.isNotEmpty;
    final isAIWorking = hasAIExplanation || widget.aiErrorMessage == null;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAIWorking
              ? [
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
                ]
              : [
                  AppConstants.errorColor.withOpacity(0.1),
                  AppConstants.errorColor.withOpacity(0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: isAIWorking
              ? Colors.orange.withOpacity(0.3)
              : AppConstants.errorColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAIWorking
                      ? Colors.orange.withOpacity(0.15)
                      : AppConstants.errorColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAIWorking ? Icons.warning_amber_rounded : Icons.cloud_off_rounded,
                  color: isAIWorking ? Colors.orange.shade700 : AppConstants.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Text(
                  isAIWorking ? 'AI Cannot Price This Item' : 'AI Service Unavailable',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.tertiaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // AI Explanation or Error Message
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isAIWorking ? Icons.lightbulb_outline : Icons.info_outline,
                color: isAIWorking ? Colors.orange.shade700 : AppConstants.errorColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasAIExplanation) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          explanation!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingM),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Tip: Use the actual product name for accurate AI pricing',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppConstants.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        widget.aiErrorMessage ?? 'AI service is currently unavailable',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacingS),
                    const Text(
                      'You can still list your product by setting your own price below.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppConstants.systemGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAISuggestionCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // AI Icon and Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              const Expanded(
                child: Text(
                  'AI Price Suggestion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.tertiaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Suggested Price
          Text(
            '\$${suggestedPrice!.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),

          // Confidence Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingXs,
            ),
            decoration: BoxDecoration(
              color: _getConfidenceColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 16,
                  color: _getConfidenceColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(confidence! * 100).toInt()}% Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getConfidenceColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Divider
          Container(
            height: 1,
            color: AppConstants.systemGray4,
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Explanation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why this price?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.tertiaryColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      explanation!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set Your Price',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          hasValidAISuggestion
              ? 'You can accept the AI suggestion or set your own price'
              : 'Enter the price you want to list your product for',
          style: const TextStyle(
            fontSize: 15,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),

        // Price Input
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 20, right: 8),
              child: Text(
                '\$',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.systemGray2,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: '0.00',
            filled: true,
            fillColor: AppConstants.systemGray6,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
              borderSide: const BorderSide(
                color: AppConstants.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (hasValidAISuggestion) {
      // Show both options when AI is available
      return Column(
        children: [
          // Accept AI Price Button
          CNButton(
            label: _isSubmitting ? 'Listing Product...' : 'Accept AI Price',
            onPressed: _isSubmitting ? null : () => _handleSetPrice(true),
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Set Custom Price Button
          CNButton(
            label: 'Set My Price',
            onPressed: _isSubmitting ? null : () => _handleSetPrice(false),
          ),
        ],
      );
    } else {
      // Show only manual price option when AI is unavailable
      return CNButton(
        label: _isSubmitting ? 'Listing Product...' : 'List Product',
        onPressed: _isSubmitting ? null : () => _handleSetPrice(false),
      );
    }
  }

  Color _getConfidenceColor() {
    if (confidence == null) return Colors.grey;
    if (confidence! >= 0.8) return Colors.green;
    if (confidence! >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
