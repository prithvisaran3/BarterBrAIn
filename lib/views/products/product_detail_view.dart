import 'package:cached_network_image/cached_network_image.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/trade_service.dart';
import '../../services/firebase_service.dart';
import '../chat/chat_detail_view.dart';

class ProductDetailView extends StatefulWidget {
  final ProductModel product;

  const ProductDetailView({super.key, required this.product});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final _authController = Get.find<AuthController>();
  final _chatService = Get.find<ChatService>();
  final _tradeService = Get.find<TradeService>();
  final _firebaseService = Get.find<FirebaseService>();

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _isLoading = false;
  UserModel? _productOwner;
  List<ProductModel> _myProducts = [];
  List<String> _selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load product owner info
      final ownerDoc = await _firebaseService.firestore
          .collection('users')
          .doc(widget.product.userId)
          .get();

      if (ownerDoc.exists) {
        _productOwner = UserModel.fromFirestore(ownerDoc);
      }

      // Load current user's products
      final currentUserId = _authController.firebaseUser.value?.uid;
      if (currentUserId != null) {
        final myProductsSnapshot = await _firebaseService.firestore
            .collection('products')
            .where('userId', isEqualTo: currentUserId)
            .where('isTraded', isEqualTo: false)
            .where('isActive', isEqualTo: true)
            .get();

        _myProducts = myProductsSnapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      print('❌ DEBUG: Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _calculatePriceDifference() {
    if (_selectedProductIds.isEmpty) return widget.product.price;

    double myTotal = 0;
    for (var id in _selectedProductIds) {
      final product = _myProducts.firstWhere((p) => p.id == id);
      myTotal += product.price;
    }

    return (widget.product.price - myTotal).abs();
  }

  String _getPaymentMessage() {
    if (_selectedProductIds.isEmpty) return '';

    double myTotal = 0;
    for (var id in _selectedProductIds) {
      final product = _myProducts.firstWhere((p) => p.id == id);
      myTotal += product.price;
    }

    final difference = widget.product.price - myTotal;

    if (difference.abs() <= 10) {
      return '✅ Direct trade possible (difference: \$${difference.abs().toStringAsFixed(2)})';
    } else if (difference > 0) {
      return '💰 You need to pay extra: \$${difference.toStringAsFixed(2)}';
    } else {
      return '💰 They need to pay extra: \$${difference.abs().toStringAsFixed(2)}';
    }
  }

  Future<void> _startChat() async {
    if (_selectedProductIds.isEmpty) {
      Get.snackbar(
        'Select Products',
        'Please select at least one of your products to trade',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = _authController.userModel.value;
      if (currentUser == null || _productOwner == null) {
        throw Exception('User data not loaded');
      }

      print('💬 DEBUG: Starting chat...');

      // Prepare product details for AI
      final initiatorProductsMap = <String, dynamic>{};
      for (var productId in _selectedProductIds) {
        final product = _myProducts.firstWhere((p) => p.id == productId);
        initiatorProductsMap[productId] = {
          'name': product.name,
          'price': product.price,
          'details': product.details,
          'condition': product.condition,
          'imageUrls': product.imageUrls,
          'brand': product.brand,
          'ageInMonths': product.ageInMonths,
        };
      }

      final recipientProductsMap = <String, dynamic>{
        widget.product.id: {
          'name': widget.product.name,
          'price': widget.product.price,
          'details': widget.product.details,
          'condition': widget.product.condition,
          'imageUrls': widget.product.imageUrls,
          'brand': widget.product.brand,
          'ageInMonths': widget.product.ageInMonths,
        }
      };

      print('📦 DEBUG: Initiator products: ${initiatorProductsMap.keys.length}');
      print('📦 DEBUG: Recipient products: ${recipientProductsMap.keys.length}');

      // Create or get existing chat
      final chat = await _chatService.createChat(
        currentUserId: currentUser.uid,
        currentUserName: currentUser.displayName ?? 'Unknown',
        currentUserPhoto: currentUser.profilePhotoUrl,
        otherUserId: _productOwner!.uid,
        otherUserName: _productOwner!.displayName,
        otherUserPhoto: _productOwner!.profilePhotoUrl,
        initiatorProducts: initiatorProductsMap,
        recipientProducts: recipientProductsMap,
      );

      print('✅ DEBUG: Chat created: ${chat.id}');

      // Create trade
      final trade = await _tradeService.createTrade(
        chatId: chat.id,
        initiatorUserId: currentUser.uid,
        recipientUserId: _productOwner!.uid,
        initiatorProductIds: _selectedProductIds,
        recipientProductIds: [widget.product.id],
      );

      print('✅ DEBUG: Trade created: ${trade.id}');

      // Navigate to chat
      Get.off(() => ChatDetailView(
            chatId: chat.id,
            otherUserId: _productOwner!.uid,
            otherUserName: _productOwner!.displayName,
            otherUserPhoto: _productOwner!.profilePhotoUrl,
          ));

      Get.snackbar(
        'Chat Started!',
        'You can now discuss the trade with ${_productOwner!.displayName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.successColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ DEBUG: Error starting chat: $e');
      Get.snackbar(
        'Error',
        'Failed to start chat. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Share product
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel
                  _buildImageCarousel(),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Price
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.tertiaryColor,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '\$${widget.product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (widget.product.aiSuggestedPrice != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'AI Suggested: \$${widget.product.aiSuggestedPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppConstants.systemGray,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadge(widget.product.brand, Icons.business_outlined),
                            _buildBadge(
                              widget.product.condition.toUpperCase(),
                              Icons.stars_outlined,
                            ),
                            _buildBadge(
                              '${widget.product.ageInMonths} months old',
                              Icons.access_time_outlined,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.tertiaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.details,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppConstants.textSecondary,
                            height: 1.5,
                          ),
                        ),

                        if (widget.product.productLink != null) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              // TODO: Open link
                            },
                            child: Text(
                              'Product Link: ${widget.product.productLink}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Owner Info
                        if (_productOwner != null) _buildOwnerInfo(),

                        const SizedBox(height: 24),

                        // Select Your Products Section
                        _buildProductSelection(),

                        const SizedBox(height: 24),

                        // Start Chat Button
                        CNButton(
                          label: _isLoading ? 'Starting Chat...' : 'Start Chat',
                          onPressed: _isLoading ? null : _startChat,
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.product.imageUrls.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.product.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppConstants.systemGray6,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppConstants.systemGray6,
                  child: const Center(child: Icon(Icons.error)),
                ),
              );
            },
          ),

          // Page Indicator
          if (widget.product.imageUrls.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.product.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? AppConstants.primaryColor
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppConstants.systemGray),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.systemGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: _productOwner!.profilePhotoUrl != null
                ? CachedNetworkImageProvider(_productOwner!.profilePhotoUrl!)
                : null,
            child: _productOwner!.profilePhotoUrl == null
                ? Text(_productOwner!.displayName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productOwner!.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.tertiaryColor,
                  ),
                ),
                Text(
                  _productOwner!.major,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Products to Trade',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
        const SizedBox(height: 12),

        if (_myProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.systemGray6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'You don\'t have any products listed yet. Add a product first!',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          )
        else
          ..._myProducts.map((product) => _buildProductCheckbox(product)),

        if (_selectedProductIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              _getPaymentMessage(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductCheckbox(ProductModel product) {
    final isSelected = _selectedProductIds.contains(product.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedProductIds.remove(product.id);
          } else {
            _selectedProductIds.add(product.id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : AppConstants.systemGray6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.imageUrls.first,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.tertiaryColor,
                    ),
                  ),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? AppConstants.primaryColor
                  : AppConstants.systemGray2,
            ),
          ],
        ),
      ),
    );
  }
}

