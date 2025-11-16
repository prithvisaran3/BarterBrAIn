import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../models/product_model.dart';
import '../../services/firebase_service.dart';

class EditProductView extends StatefulWidget {
  final ProductModel product;

  const EditProductView({super.key, required this.product});

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = Get.find<FirebaseService>();

  late TextEditingController _nameController;
  late TextEditingController _detailsController;
  late TextEditingController _brandController;
  late TextEditingController _ageController;
  late TextEditingController _linkController;
  late TextEditingController _priceController;

  String _selectedCondition = 'good';
  List<String> _imageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _detailsController = TextEditingController(text: widget.product.details);
    _brandController = TextEditingController(text: widget.product.brand);
    _ageController = TextEditingController(text: widget.product.ageInMonths.toString());
    _linkController = TextEditingController(text: widget.product.productLink ?? '');
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(2));
    _selectedCondition = widget.product.condition;
    _imageUrls = List.from(widget.product.imageUrls);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _brandController.dispose();
    _ageController.dispose();
    _linkController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imageUrls.length >= 3) {
      Get.snackbar(
        'Maximum Images',
        'You can only add up to 3 images',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final source = await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppConstants.systemGray4,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Image',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppConstants.primaryColor),
                title: const Text('Take Photo'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppConstants.primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      isDismissible: true,
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() => _isLoading = true);

        // Upload to Firebase Storage
        final userId = widget.product.userId;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_${_imageUrls.length}.jpg';
        final ref = _firebaseService.storage.ref().child('products/$userId/$fileName');

        await ref.putFile(File(image.path));
        final downloadUrl = await ref.getDownloadURL();

        setState(() {
          _imageUrls.add(downloadUrl);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ DEBUG: Error picking image: $e');
      setState(() => _isLoading = false);
      Get.snackbar(
        'Error',
        'Failed to add image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _removeImage(int index) async {
    final imageUrl = _imageUrls[index];

    try {
      // Delete from storage
      await _firebaseService.storage.refFromURL(imageUrl).delete();

      setState(() {
        _imageUrls.removeAt(index);
      });

      Get.snackbar(
        'Image Removed',
        'Image deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ DEBUG: Error deleting image: $e');
      Get.snackbar(
        'Error',
        'Failed to delete image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrls.isEmpty) {
      Get.snackbar(
        'No Images',
        'Please add at least one image',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedProduct = ProductModel(
        id: widget.product.id,
        userId: widget.product.userId,
        name: _nameController.text.trim(),
        details: _detailsController.text.trim(),
        brand: _brandController.text.trim(),
        ageInMonths: int.parse(_ageController.text.trim()),
        productLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        condition: _selectedCondition,
        price: double.parse(_priceController.text.trim()),
        imageUrls: _imageUrls,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
        isActive: widget.product.isActive,
        aiSuggestedPrice: widget.product.aiSuggestedPrice,
        aiExplanation: widget.product.aiExplanation,
        isTraded: widget.product.isTraded,
        tradedWith: widget.product.tradedWith,
        tradedDate: widget.product.tradedDate,
        tradeId: widget.product.tradeId,
      );

      await _firebaseService.firestore
          .collection('products')
          .doc(widget.product.id)
          .update(updatedProduct.toFirestore());

      Get.back();
      Get.snackbar(
        'Updated!',
        'Product updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.successColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ DEBUG: Error updating product: $e');
      Get.snackbar(
        'Error',
        'Failed to update product',
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
        title: const Text('Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Images
              _buildImageSection(),
              const SizedBox(height: 24),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g., Blue Food Plate',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Details
              TextFormField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: 'Details *',
                  hintText: 'Describe your product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product details';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: InputDecoration(
                  labelText: 'Brand *',
                  hintText: 'e.g., Apple, Nike',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter brand name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age (in months) *',
                  hintText: '12',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter product age';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price *',
                  hintText: '25.00',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Condition
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: InputDecoration(
                  labelText: 'Condition *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('New')),
                  DropdownMenuItem(value: 'good', child: Text('Good')),
                  DropdownMenuItem(value: 'fair', child: Text('Fair')),
                  DropdownMenuItem(value: 'bad', child: Text('Bad')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCondition = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Product Link (Optional)
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Product Link (Optional)',
                  hintText: 'https://...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              CNButton(
                label: _isLoading ? 'Saving...' : 'Save Changes',
                onPressed: _isLoading ? null : _saveChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add up to 3 images',
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageUrls.length + (_imageUrls.length < 3 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _imageUrls.length) {
                // Show existing image
                return _buildImageItem(_imageUrls[index], index);
              } else {
                // Show add button
                return _buildAddImageButton();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(String imageUrl, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.systemGray4, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppConstants.errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _pickImage,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppConstants.systemGray6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.systemGray4, width: 2),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 32, color: AppConstants.systemGray2),
                  SizedBox(height: 4),
                  Text(
                    'Add Image',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.systemGray2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

