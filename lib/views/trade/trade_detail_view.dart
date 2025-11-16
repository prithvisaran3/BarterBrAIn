import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../models/trade_model.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

class TradeDetailView extends StatefulWidget {
  final TradeModel trade;
  
  const TradeDetailView({
    super.key,
    required this.trade,
  });

  @override
  State<TradeDetailView> createState() => _TradeDetailViewState();
}

class _TradeDetailViewState extends State<TradeDetailView> with SingleTickerProviderStateMixin {
  final _firebaseService = Get.find<FirebaseService>();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  UserModel? _initiatorUser;
  UserModel? _recipientUser;
  List<ProductModel> _initiatorProducts = [];
  List<ProductModel> _recipientProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadTradeData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
  }

  Future<void> _loadTradeData() async {
    try {
      print('📦 DEBUG [TradeDetail]: Loading trade data...');
      
      // Load users
      final initiatorDoc = await _firebaseService.firestore
          .collection('users')
          .doc(widget.trade.initiatorUserId)
          .get();
      final recipientDoc = await _firebaseService.firestore
          .collection('users')
          .doc(widget.trade.recipientUserId)
          .get();
      
      if (initiatorDoc.exists) {
        _initiatorUser = UserModel.fromFirestore(initiatorDoc);
      }
      if (recipientDoc.exists) {
        _recipientUser = UserModel.fromFirestore(recipientDoc);
      }
      
      // Load products
      for (var productId in widget.trade.initiatorProductIds) {
        final productDoc = await _firebaseService.firestore
            .collection('products')
            .doc(productId)
            .get();
        if (productDoc.exists) {
          _initiatorProducts.add(ProductModel.fromFirestore(productDoc));
        }
      }
      
      for (var productId in widget.trade.recipientProductIds) {
        final productDoc = await _firebaseService.firestore
            .collection('products')
            .doc(productId)
            .get();
        if (productDoc.exists) {
          _recipientProducts.add(ProductModel.fromFirestore(productDoc));
        }
      }
      
      setState(() {
        _isLoading = false;
      });
      
      print('✅ DEBUG [TradeDetail]: Trade data loaded successfully');
    } catch (e) {
      print('❌ DEBUG [TradeDetail]: Error loading trade data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Trade Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      _buildStatusCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Trade Participants
                      _buildParticipantsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Products Section
                      _buildProductsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Trade Details
                      _buildTradeDetailsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Sustainability Impact (if available)
                      if (widget.trade.sustainabilityImpact != null) ...[
                        _buildSustainabilitySection(),
                        const SizedBox(height: 24),
                      ],
                      
                      // Timeline
                      _buildTimelineSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isCompleted = widget.trade.isCompleted;
    final statusColor = isCompleted ? Colors.green : Colors.orange;
    final statusText = isCompleted ? 'Completed' : 'In Progress';
    final statusIcon = isCompleted ? Icons.check_circle : Icons.access_time;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.green.shade600, Colors.green.shade400]
              : [Colors.orange.shade600, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? 'Trade completed successfully'
                      : 'Trade negotiation ongoing',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PARTICIPANTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildUserCard(_initiatorUser, 'Trader 1'),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.swap_horiz_rounded,
              color: AppConstants.primaryColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserCard(_recipientUser, 'Trader 2'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel? user, String label) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.systemGray6,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: AppConstants.textSecondary)),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (user.profilePhotoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: CachedNetworkImage(
                imageUrl: user.profilePhotoUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppConstants.systemGray6,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  user.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            user.displayName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            user.universityId.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRODUCTS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        
        // Initiator's Products
        if (_initiatorProducts.isNotEmpty) ...[
          Text(
            '${_initiatorUser?.displayName ?? "Trader 1"}\'s Items',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._initiatorProducts.map((product) => _buildProductCard(product)),
          const SizedBox(height: 16),
        ],
        
        // Recipient's Products
        if (_recipientProducts.isNotEmpty) ...[
          Text(
            '${_recipientUser?.displayName ?? "Trader 2"}\'s Items',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._recipientProducts.map((product) => _buildProductCard(product)),
        ],
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
              placeholder: (context, url) => Container(
                color: AppConstants.systemGray6,
                child: const Center(child: CircularProgressIndicator()),
              ),
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
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.details,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeDetailsSection() {
    final initiatorTotal = widget.trade.initiatorTotalValue;
    final recipientTotal = widget.trade.recipientTotalValue;
    final priceDiff = widget.trade.priceDifference;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRADE SUMMARY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Trader 1 Total',
            '\$${initiatorTotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Trader 2 Total',
            '\$${recipientTotal.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Price Difference',
            '\$${priceDiff.toStringAsFixed(2)}',
            valueColor: priceDiff > 0 ? Colors.orange : Colors.green,
          ),
          if (widget.trade.payingUserId != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'Payment Required By',
              widget.trade.payingUserId == _initiatorUser?.uid
                  ? _initiatorUser?.displayName ?? 'Trader 1'
                  : _recipientUser?.displayName ?? 'Trader 2',
              valueColor: AppConstants.errorColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppConstants.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildSustainabilitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SUSTAINABILITY IMPACT',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.trade.sustainabilityImpact!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIMELINE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppConstants.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineItem(
          'Trade Started',
          _formatDate(widget.trade.createdAt),
          Icons.start,
          Colors.blue,
          isFirst: true,
        ),
        if (widget.trade.isCompleted)
          _buildTimelineItem(
            'Trade Completed',
            _formatDate(widget.trade.updatedAt),
            Icons.check_circle,
            Colors.green,
            isLast: true,
          )
        else
          _buildTimelineItem(
            'Last Updated',
            _formatDate(widget.trade.updatedAt),
            Icons.update,
            Colors.orange,
            isLast: true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 16,
                  color: AppConstants.systemGray4,
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppConstants.systemGray4,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }
}

