import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../models/trade_model.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../services/trade_service.dart';
import '../notifications/notifications_view.dart';
import '../products/product_detail_view.dart';

/// Enhanced Interactive Home View with Animations
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  final _authController = Get.find<AuthController>();
  final _firebaseService = Get.find<FirebaseService>();
  final _tradeService = Get.find<TradeService>();
  final _notificationService = Get.find<NotificationService>();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  final _scrollController = ScrollController();
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  int _totalProducts = 0;
  int _activeTrades = 0;
  int _completedTrades = 0;

  @override
  void initState() {
    super.initState();

    // Header animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Stats animation
    _statsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _headerAnimationController.forward();
    _statsAnimationController.forward();

    _loadStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final currentUserId = _authController.firebaseUser.value?.uid ?? '';
    if (currentUserId.isEmpty) return;

    try {
      // Load product count
      final productsSnapshot = await _firebaseService.firestore
          .collection('products')
          .where('userId', isEqualTo: currentUserId)
          .where('isActive', isEqualTo: true)
          .get();

      // Load trades
      final tradesSnapshot = await _firebaseService.firestore
          .collection('trades')
          .where('initiatorUserId', isEqualTo: currentUserId)
          .get();

      final trades = tradesSnapshot.docs.map((doc) => TradeModel.fromFirestore(doc)).toList();

      if (mounted) {
        setState(() {
          _totalProducts = productsSnapshot.docs.length;
          _activeTrades = trades.where((t) => t.status == 'active' || t.status == 'pending').length;
          _completedTrades = trades.where((t) => t.status == 'completed').length;
        });
      }
    } catch (e) {
      print('❌ ERROR [HomeView]: Failed to load stats: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadStats();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authController.firebaseUser.value?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: AppConstants.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Animated Header
              _buildAnimatedHeader(),

              // Welcome Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: _buildWelcomeSection(),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildStatsCards(),
                ),
              ),

              // Current Trades Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: _buildTradesSection(currentUserId),
                ),
              ),

              // Featured Products Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  child: _buildFeaturedProductsSection(currentUserId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      title: SlideTransition(
        position: _headerSlideAnimation,
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: Row(
            children: [
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/logo/BarterBrAIn-icon.png',
                  width: 40,
                  height: 40,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'BarterBrAIn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.tertiaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Obx(() {
          final unreadCount = _notificationService.unreadCount.value;
          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                color: AppConstants.secondaryColor,
                onPressed: () {
                  Get.to(() => const NotificationsView());
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _headerFadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _headerFadeAnimation.value)),
            child: child,
          ),
        );
      },
      child: Obx(() {
        final user = _authController.userModel.value;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor.withOpacity(0.1),
                AppConstants.primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppConstants.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.firstName ?? 'User',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.tertiaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to trade today?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: user?.profilePhotoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user!.profilePhotoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.person, size: 32, color: Colors.white),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatsCards() {
    return AnimatedBuilder(
      animation: _statsAnimationController,
      builder: (context, child) {
        final value = Curves.easeOut.transform(_statsAnimationController.value);
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'My Products',
              _totalProducts.toString(),
              Icons.inventory_2,
              Colors.blue,
              0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active Trades',
              _activeTrades.toString(),
              Icons.swap_horiz,
              AppConstants.primaryColor,
              150,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Completed',
              _completedTrades.toString(),
              Icons.check_circle,
              Colors.green,
              300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, int delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.elasticOut,
      builder: (context, double animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          // Navigate to My Products view when tapping "My Products" card
          if (label == 'My Products') {
            Get.toNamed('/my-products');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradesSection(String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        const Text(
          'Current Trades',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
        const SizedBox(height: 16),

        // Stream trades
        StreamBuilder<List<TradeModel>>(
          stream: _tradeService.getUserTrades(currentUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildEmptyTrades();
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyTrades();
            }

            final trades = snapshot.data!;
            final activeTrades = trades.where((t) => t.isActive).toList();
            final completedTrades = trades.where((t) => t.isCompleted).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In Progress Trades
                if (activeTrades.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'In Progress (${activeTrades.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeTrades.length,
                      itemBuilder: (context, index) {
                        return _buildTradeCardHorizontal(activeTrades[index], currentUserId);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Completed Trades
                if (completedTrades.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completed (${completedTrades.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: completedTrades.length,
                      itemBuilder: (context, index) {
                        return _buildTradeCardHorizontal(completedTrades[index], currentUserId);
                      },
                    ),
                  ),
                ],

                // Show empty state if no trades
                if (activeTrades.isEmpty && completedTrades.isEmpty) _buildEmptyTrades(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyTrades() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.swap_horiz, size: 48, color: AppConstants.systemGray2),
          SizedBox(height: 12),
          Text(
            'No trades yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Start trading to see your activity here',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTradeCardHorizontal(TradeModel trade, String currentUserId) {
    final isInitiator = trade.initiatorUserId == currentUserId;
    final myProductIds = isInitiator ? trade.initiatorProductIds : trade.recipientProductIds;
    final theirProductIds = isInitiator ? trade.recipientProductIds : trade.initiatorProductIds;

    final statusColor = trade.isCompleted ? Colors.green : Colors.orange;
    final statusText = trade.isCompleted ? 'Completed' : 'In Progress';

    return GestureDetector(
      onTap: () {
        // Navigate to trade details or chat
        if (trade.isCompleted) {
          Get.toNamed('/trade-detail', arguments: trade);
        } else {
          // TODO: Navigate to chat for in-progress trades
          Get.toNamed('/trade-detail', arguments: trade);
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Products Row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // My Product
                  Expanded(
                    child: FutureBuilder(
                      future: _firestore.collection('products').doc(myProductIds.first).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppConstants.systemGray6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }
                        final product = ProductModel.fromFirestore(snapshot.data!);
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrls.first,
                                height: 60,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppConstants.systemGray6,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Swap Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),

                  // Their Product
                  Expanded(
                    child: FutureBuilder(
                      future: _firestore.collection('products').doc(theirProductIds.first).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppConstants.systemGray6,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }
                        final product = ProductModel.fromFirestore(snapshot.data!);
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrls.first,
                                height: 60,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppConstants.systemGray6,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Status and Date
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trade.completedAt != null)
                    Text(
                      _formatTradeDate(trade.completedAt!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTradeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Widget _buildFeaturedProductsSection(String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.tertiaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all products view
                Get.toNamed('/all-products');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stream products (OPTIMIZED: Limited to 10 items for fast loading)
        StreamBuilder<QuerySnapshot>(
          stream: _firebaseService.firestore
              .collection('products')
              .where('isTraded', isEqualTo: false)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(10) // ⚡ PERFORMANCE: Only load 10 products
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  height: 50,
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyProducts();
            }

            // Filter out current user's products
            final allProducts = snapshot.data!.docs
                .map((doc) => ProductModel.fromFirestore(doc))
                .where((product) => product.userId != currentUserId)
                .toList();

            if (allProducts.isEmpty) {
              return _buildEmptyProducts();
            }

            return Column(
              children: [
                // Show products (already limited to 10 in query)
                ...allProducts.map((product) => _buildProductCard(product)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyProducts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppConstants.systemGray2),
          SizedBox(height: 12),
          Text(
            'No products yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Be the first to add a product!',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Get.to(
            () => ProductDetailView(product: product),
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        },
        child: Hero(
          tag: 'product_${product.id}',
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with Owner Info Overlay
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrls.first,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppConstants.systemGray6,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppConstants.systemGray6,
                          child: const Center(child: Icon(Icons.error)),
                        ),
                      ),
                    ),
                    // Owner Info Overlay
                    Positioned(
                      top: 8,
                      left: 8,
                      child: FutureBuilder(
                        future: _firestore.collection('users').doc(product.userId).get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          }
                          final userData = snapshot.data!.data() as Map<String, dynamic>;
                          final displayName = userData['displayName'] ?? 'Unknown';
                          final photoUrl = userData['profilePhotoUrl'] as String?;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundImage: photoUrl != null
                                      ? CachedNetworkImageProvider(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? Text(
                                          displayName[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 10, color: Colors.white),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  displayName.length > 15
                                      ? '${displayName.substring(0, 15)}...'
                                      : displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Product Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.tertiaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '\$${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppConstants.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildProductBadge(
                            product.condition.toUpperCase(),
                            Icons.stars_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppConstants.systemGray),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppConstants.systemGray,
            ),
          ),
        ],
      ),
    );
  }
}
