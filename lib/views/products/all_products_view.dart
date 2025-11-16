import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../services/firebase_service.dart';
import 'product_detail_view.dart';

/// All Products View - Shows all available products for trading
class AllProductsView extends StatefulWidget {
  const AllProductsView({super.key});

  @override
  State<AllProductsView> createState() => _AllProductsViewState();
}

class _AllProductsViewState extends State<AllProductsView> {
  final _authController = Get.find<AuthController>();
  final _firebaseService = Get.find<FirebaseService>();
  
  FirebaseFirestore get _firestore => _firebaseService.firestore;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authController.firebaseUser.value?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'All Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('products')
            .where('isTraded', isEqualTo: false)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppConstants.systemGray2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check back later for new items',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Filter out current user's products
          final allProducts = snapshot.data!.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .where((product) => product.userId != currentUserId)
              .toList();

          if (allProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppConstants.systemGray2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No products from other users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start trading by adding your own products',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort by price
          allProducts.sort((a, b) => a.price.compareTo(b.price));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(allProducts[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProductDetailView(product: product),
          transition: Transition.rightToLeft,
          duration: const Duration(milliseconds: 300),
        );
      },
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.systemGray6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_outlined, size: 12, color: AppConstants.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          product.condition.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}

