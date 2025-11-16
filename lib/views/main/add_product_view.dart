import 'dart:async';
import 'dart:io';

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../services/ai_service.dart';
import '../../services/firebase_service.dart';
import '../products/price_suggestion_view.dart';

class AddProductView extends StatefulWidget {
  const AddProductView({super.key});

  @override
  State<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<AddProductView> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  final _brandController = TextEditingController();
  final _ageController = TextEditingController();
  final _linkController = TextEditingController();

  final _authController = Get.find<AuthController>();
  final _firebaseService = Get.find<FirebaseService>();
  final _aiService = AIService();

  final List<File?> _images = [null, null, null];
  final List<String?> _imageUrls = [null, null, null]; // Uploaded Firebase URLs
  final List<String?> _storagePaths = [null, null, null]; // Storage paths for deletion
  final List<bool> _isUploadingImage = [false, false, false]; // Loading state per image
  String _selectedCondition = 'good';
  bool _isGettingAIPrice = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _conditions = ['new', 'good', 'fair', 'bad'];

  // AI Loading animation state
  int _currentMessageIndex = 0;
  Timer? _messageTimer;

  final List<String> _aiLoadingMessages = [
    '🤖 Waking up our AI overlord...',
    '🧠 Teaching AI what money is...',
    '💭 AI is judging your product choices...',
    '🎯 Consulting the ancient pricing scrolls...',
    '📊 Running complex calculations... (2+2=4)',
    '🔮 Gazing into the crystal ball of capitalism...',
    "💸 Calculating how broke you'll be...",
    '🎲 Rolling dice... just kidding, using AI!',
    '🌟 Asking the universe for guidance...',
    '🤔 AI is having second thoughts...',
    '💡 Pretending to be smart...',
    '🎪 Putting on a show for you...',
    '⚡ Channeling inner Jeff Bezos...',
    '🎭 Dramatically overthinking this...',
    '🚀 Almost there... maybe...',
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _brandController.dispose();
    _ageController.dispose();
    _linkController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startMessageCycling() {
    _currentMessageIndex = 0;
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _aiLoadingMessages.length;
        });
      }
    });
  }

  void _stopMessageCycling() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  Future<void> _pickImage(int index) async {
    print('📸 DEBUG: Starting image picker for slot $index');
    
    // Show iOS-style action sheet
    final source = await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusL),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppConstants.spacingS),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppConstants.systemGray4,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.tertiaryColor,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppConstants.primaryColor),
                title: const Text('Take Photo'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppConstants.primaryColor),
                title: const Text('Choose from Gallery'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
                child: CNButton(
                  label: 'Cancel',
                  onPressed: () => Get.back(),
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
            ],
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );

    if (source == null) {
      print('⚠️ DEBUG: User cancelled image source selection');
      return;
    }

    print(
        '📸 DEBUG: Image source selected: ${source == ImageSource.camera ? "Camera" : "Gallery"}');

    // Pick image from selected source
    // Note: image_picker handles permission requests automatically using Info.plist
    final ImagePicker picker = ImagePicker();
    try {
      print('📸 DEBUG: Opening image picker for slot $index...');

      // Try with different settings for better simulator compatibility
      final XFile? image = await picker
          .pickImage(
        source: source,
        imageQuality: 100, // Higher quality, less compression issues
        preferredCameraDevice: CameraDevice.rear,
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ DEBUG: Image picker timeout');
          return null;
        },
      );

      if (image != null) {
        print('✅ DEBUG: Image selected: ${image.path}');
        print('✅ DEBUG: Image size: ${await image.length()} bytes');

        // Set local file and start uploading
        setState(() {
          _images[index] = File(image.path);
          _isUploadingImage[index] = true;
        });

        // Upload to Firebase Storage immediately
        await _uploadImageToStorage(index);
      } else {
        print('⚠️ DEBUG: No image selected by user');
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error picking image: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');

      String userMessage = 'Unable to access photo. Please try again.';
      String title = 'Photo Error';

      if (e.toString().contains('invalid_image') ||
          e.toString().contains('Cannot load representation')) {
        // iOS Simulator issue - can't load certain image formats
        title = 'Simulator Limitation';
        userMessage = 'The iOS Simulator has trouble loading some photos. Try:\n'
            '1. Use Camera instead of Gallery\n'
            '2. Drag & drop an image into the Simulator window\n'
            '3. Save to Photos, then try Gallery again\n'
            '4. Test on a real iPhone device';
        print('💡 DEBUG: This is a known iOS Simulator limitation with image formats');
        print('💡 TIP: Drag an image file directly into the simulator to add it to Photos');
      } else if (e.toString().contains('camera')) {
        userMessage = 'Camera access denied. Please enable camera permissions in Settings.';
      } else if (e.toString().contains('photo') || e.toString().contains('library')) {
        userMessage = 'Photo library access denied. Please enable photo permissions in Settings.';
      }

      Get.snackbar(
        title,
        userMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: title == 'Simulator Limitation'
            ? AppConstants.systemGray.withOpacity(0.95)
            : AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
        duration: title == 'Simulator Limitation'
            ? const Duration(seconds: 6) // Longer for reading solutions
            : const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  Future<void> _uploadImageToStorage(int index) async {
    final userId = _authController.firebaseUser.value?.uid;

    if (userId == null || _images[index] == null) {
      setState(() => _isUploadingImage[index] = false);
      return;
    }

    print('📤 DEBUG: Uploading image $index to storage...');

    int retryCount = 0;
    const maxRetries = 2;
    bool uploadSuccess = false;

    while (!uploadSuccess && retryCount <= maxRetries) {
      try {
        if (retryCount > 0) {
          print('🔄 DEBUG: Retry attempt $retryCount for image $index');
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }

        final fileName = 'products/$userId/${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
        print('📤 DEBUG: Storage path: $fileName (attempt ${retryCount + 1})');
        final ref = _firebaseService.storage.ref().child(fileName);

        await ref.putFile(_images[index]!);
        print('✅ DEBUG: Image $index uploaded to storage');

        final url = await ref.getDownloadURL();
        print('✅ DEBUG: Image $index URL obtained: ${url.substring(0, 50)}...');

        setState(() {
          _imageUrls[index] = url;
          _storagePaths[index] = fileName;
          _isUploadingImage[index] = false;
        });

        uploadSuccess = true;
        print('✅ DEBUG: Image $index ready');
      } catch (e) {
        retryCount++;
        print('❌ DEBUG: Failed to upload image $index (attempt $retryCount): $e');

        if (retryCount > maxRetries) {
          print('❌ DEBUG: Max retries reached for image $index');
          setState(() {
            _images[index] = null;
            _isUploadingImage[index] = false;
          });

          Get.snackbar(
            'Upload Failed',
            'Failed to upload photo ${index + 1}. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstants.errorColor.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
          break;
        }
      }
    }
  }

  Future<void> _removeImage(int index) async {
    print('🗑️ DEBUG: Removing image $index...');

    // Delete from Firebase Storage if uploaded
    if (_storagePaths[index] != null) {
      try {
        print('🗑️ DEBUG: Deleting from storage: ${_storagePaths[index]}');
        await _firebaseService.storage.ref().child(_storagePaths[index]!).delete();
        print('✅ DEBUG: Image $index deleted from storage');
      } catch (e) {
        print('⚠️ DEBUG: Failed to delete image from storage: $e');
        // Continue anyway - image might already be deleted
      }
    }

    setState(() {
      _images[index] = null;
      _imageUrls[index] = null;
      _storagePaths[index] = null;
      _isUploadingImage[index] = false;
    });

    print('✅ DEBUG: Image $index removed');
  }

  List<String> _getUploadedImageUrls() {
    print('📋 DEBUG: Collecting uploaded image URLs...');
    final List<String> imageUrls = [];

    for (int i = 0; i < _imageUrls.length; i++) {
      if (_imageUrls[i] != null) {
        imageUrls.add(_imageUrls[i]!);
        print('✅ DEBUG: Image $i URL: ${_imageUrls[i]!.substring(0, 50)}...');
      }
    }

    print('✅ DEBUG: Total uploaded images: ${imageUrls.length}');
    return imageUrls;
  }

  Future<void> _handleGetAIPrice() async {
    print('🤖 DEBUG: Getting AI price suggestion...');

    if (!_formKey.currentState!.validate()) {
      print('⚠️ DEBUG: Form validation failed');
      return;
    }

    // Check if any images are still uploading
    if (_isUploadingImage.any((uploading) => uploading)) {
      print('⚠️ DEBUG: Images still uploading');
      Get.snackbar(
        'Please Wait',
        'Photos are still uploading. Please wait a moment.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.systemGray.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    // Check if at least one image is uploaded
    if (_imageUrls.every((url) => url == null)) {
      print('⚠️ DEBUG: No images uploaded');
      Get.snackbar(
        'Photos Required',
        'Please add at least one photo of your product',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    print('🚀 DEBUG: Form validated, calling AI API...');
    setState(() => _isGettingAIPrice = true);
    _startMessageCycling();

    try {
      // Get already-uploaded image URLs
      final imageUrls = _getUploadedImageUrls();

      // Get age in months
      final ageInMonths =
          _ageController.text.trim().isEmpty ? null : int.tryParse(_ageController.text.trim());

      // Parse accessories from description
      final accessories = _aiService.parseAccessories(_detailsController.text.trim());

      print('🤖 DEBUG: Calling Keerthi\'s Gemini API with product data...');
      print('📦 DEBUG: Product: ${_nameController.text.trim()}');
      print(
          '🏷️  DEBUG: Brand: ${_brandController.text.trim()}, Age: $ageInMonths months, Condition: $_selectedCondition');
      print('🖼️  DEBUG: Images: ${imageUrls.length} uploaded');
      print('⏱️  DEBUG: This will take 6-14 seconds...');

      // Call AI Service with Keerthi's API format
      final aiSuggestion = await _aiService.getPriceSuggestion(
        title: _nameController.text.trim(),
        description: _detailsController.text.trim(),
        brand: _brandController.text.trim(),
        ageMonths: ageInMonths,
        condition: _selectedCondition.toLowerCase(), // Ensure lowercase for API
        accessories: accessories.isNotEmpty ? accessories : null,
        images: imageUrls.isNotEmpty ? imageUrls : null, // Send uploaded image URLs
        productLink: _linkController.text.trim().isNotEmpty ? _linkController.text.trim() : null,
      );

      print('✅ DEBUG: AI suggestion received');
      print('💰 DEBUG: Suggested price: \$${aiSuggestion['value']}');

      // Navigate to price suggestion screen
      Get.to(
        () => PriceSuggestionView(
          aiSuggestion: aiSuggestion,
          productName: _nameController.text.trim(),
          productDetails: _detailsController.text.trim(),
          brand: _brandController.text.trim(),
          ageInMonths: int.parse(_ageController.text.trim()),
          condition: _selectedCondition,
          productLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
          imageUrls: imageUrls,
        ),
      );
    } catch (e, stackTrace) {
      print('❌ DEBUG: Error getting AI price suggestion');
      print('❌ DEBUG: Error: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');

      // Parse error message
      String errorReason = 'AI service is currently unavailable';

      if (e.toString().contains('timeout') || e.toString().contains('took too long')) {
        errorReason = 'Request took too long';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection') ||
          e.toString().contains('SocketException')) {
        errorReason = 'No internet connection';
      } else if (e.toString().contains('not available') || e.toString().contains('404')) {
        errorReason = 'AI service is currently unavailable';
      }

      print('📱 DEBUG: AI unavailable - navigating to manual price entry');
      print('📱 DEBUG: Reason: $errorReason');

      // Navigate to price suggestion screen WITHOUT AI data
      // User can still set manual price
      final imageUrls = _getUploadedImageUrls();

      Get.to(
        () => PriceSuggestionView(
          aiSuggestion: null, // No AI data available
          aiErrorMessage: errorReason,
          productName: _nameController.text.trim(),
          productDetails: _detailsController.text.trim(),
          brand: _brandController.text.trim(),
          ageInMonths: int.parse(_ageController.text.trim()),
          condition: _selectedCondition,
          productLink: _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
          imageUrls: imageUrls,
        ),
      );
    } finally {
      _stopMessageCycling();
      setState(() => _isGettingAIPrice = false);
      print('🚀 DEBUG: AI price request completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'List Product',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.spacingL,
                        0,
                        AppConstants.spacingL,
                        120, // Space for nav bar
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Images Section
                            _buildSectionTitle('Product Photos'),
                            const SizedBox(height: AppConstants.spacingM),
                            _buildImagePickers(),
                            const SizedBox(height: AppConstants.spacingXl),

                            // Product Info
                            _buildSectionTitle('Product Details'),
                            const SizedBox(height: AppConstants.spacingM),

                            // Product Name
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                                hintText: 'iPhone 13 Pro',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter product name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppConstants.spacingM),

                            // Brand
                            TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                                hintText: 'Apple',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter brand name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppConstants.spacingM),

                            // Details
                            TextFormField(
                              controller: _detailsController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'Describe your product...',
                                prefixIcon: Icon(Icons.description_outlined),
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter product description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppConstants.spacingM),

                            // Age and Condition Row
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Age in Months',
                                      hintText: 'e.g., 6 months old',
                                      helperText: 'How old is the product?',
                                      prefixIcon: Icon(Icons.access_time_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Age is required';
                                      }
                                      final age = int.tryParse(value);
                                      if (age == null || age < 0) {
                                        return 'Enter valid months';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppConstants.spacingM),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedCondition,
                                    decoration: const InputDecoration(
                                      labelText: 'Condition',
                                      prefixIcon: Icon(Icons.stars_outlined),
                                    ),
                                    items: _conditions.map((condition) {
                                      return DropdownMenuItem(
                                        value: condition,
                                        child: Text(
                                          condition[0].toUpperCase() + condition.substring(1),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedCondition = value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacingM),

                            // Product Link (Optional)
                            TextFormField(
                              controller: _linkController,
                              decoration: const InputDecoration(
                                labelText: 'Product Link (Optional)',
                                hintText: 'https://...',
                                prefixIcon: Icon(Icons.link_outlined),
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingXl),

                            // Set Price Button
                            CNButton(
                              label: 'Get AI Price Suggestion',
                              onPressed: _isGettingAIPrice ? null : _handleGetAIPrice,
                            ),
                            const SizedBox(height: AppConstants.spacingM),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Animated AI Loading Overlay
        if (_isGettingAIPrice) _buildAILoadingOverlay(),
      ],
    );
  }

  Widget _buildAILoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor.withOpacity(0.95),
                AppConstants.primaryColor.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppConstants.primaryColor.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Static Robot Icon (no continuous animation)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Animated Message (simplified transition)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: Text(
                  _aiLoadingMessages[_currentMessageIndex],
                  key: ValueKey<int>(_currentMessageIndex),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Simple progress indicator (no continuous animation)
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),

              const SizedBox(height: 16),

              // Estimated time
              Text(
                'Takes 6-14 seconds',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildImagePickers() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < 2 ? AppConstants.spacingM : 0,
            ),
            child: _buildImagePicker(index),
          ),
        );
      }),
    );
  }

  Widget _buildImagePicker(int index) {
    final hasImage = _images[index] != null;
    final isUploading = _isUploadingImage[index];

    return GestureDetector(
      onTap: isUploading ? null : () => _pickImage(index),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : AppConstants.systemGray6,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: hasImage ? AppConstants.primaryColor.withOpacity(0.3) : AppConstants.systemGray4,
            width: 2,
          ),
          image: hasImage && !isUploading
              ? DecorationImage(
                  image: FileImage(_images[index]!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  // Loading overlay
                  if (isUploading)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Uploading...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Remove button
                  if (!isUploading)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _removeImage(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppConstants.systemGray2,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    index == 0 ? 'Main Photo' : 'Photo ${index + 1}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
