import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../models/product_model.dart';
import '../../models/trade_model.dart';
import '../../services/ai_service.dart';
import '../../services/chat_service.dart';
import '../../services/firebase_service.dart';
import '../../services/nessie_api_service.dart';
import '../../services/notification_service.dart';
import '../../services/trade_service.dart';
import '../../services/transaction_service.dart';
import '../../widgets/payment_dialog.dart';
import '../trade/trade_finalization_view.dart';

class ChatDetailView extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const ChatDetailView({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> with TickerProviderStateMixin {
  final _authController = Get.find<AuthController>();
  final _chatService = Get.find<ChatService>();
  final _tradeService = Get.find<TradeService>();
  final _aiService = AIService();
  final _firebaseService = Get.find<FirebaseService>();
  final _nessieService = Get.find<NessieAPIService>();
  final _notificationService = Get.find<NotificationService>();
  final _transactionService = Get.find<TransactionService>();

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _showEmojiPicker = false;
  bool _isLoading = false;
  bool _isSending = false;
  bool _isLoadingAI = false;

  TradeModel? _trade;
  bool _currentUserConfirmed = false;
  ProductModel? _userProduct;
  ProductModel? _otherUserProduct;
  ChatModel? _currentChat;

  late AnimationController _tickController;
  late Animation<double> _tickAnimation;

  @override
  void initState() {
    super.initState();
    print('💬 DEBUG [ChatDetail]: Initializing chat detail view');
    print('💬 DEBUG [ChatDetail]: Chat ID: ${widget.chatId}');
    print('💬 DEBUG [ChatDetail]: Other user: ${widget.otherUserName} (${widget.otherUserId})');

    _loadChatData();
    _loadTradeData();

    try {
      // Mark messages as read
      _chatService.markMessagesAsRead(
        chatId: widget.chatId,
        userId: _authController.firebaseUser.value!.uid,
      );
      print('✅ SUCCESS [ChatDetail]: Messages marked as read');
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to mark messages as read: $e');
    }

    // Green tick animation
    _tickController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _tickAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _tickController,
        curve: Curves.elasticOut,
      ),
    );
    print('✅ SUCCESS [ChatDetail]: Animations initialized');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tickController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    print('💬 DEBUG [ChatDetail]: Loading chat data for product details...');

    try {
      final chatDoc = await _firebaseService.firestore.collection('chats').doc(widget.chatId).get();

      if (chatDoc.exists) {
        _currentChat = ChatModel.fromFirestore(chatDoc);
        print('✅ SUCCESS [ChatDetail]: Chat document loaded');

        if (_currentChat!.initiatorProducts != null && _currentChat!.recipientProducts != null) {
          print('📦 DEBUG [ChatDetail]: Product details found in chat document');
          _loadProductsFromChat();
        } else {
          print('⚠️ DEBUG [ChatDetail]: No product details in chat document');
        }
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to load chat data: $e');
    }
  }

  void _loadProductsFromChat() {
    if (_currentChat == null) return;

    try {
      final currentUserId = _authController.firebaseUser.value!.uid;

      // Determine if current user is initiator or recipient
      final isInitiator = _currentChat!.participantIds.first == currentUserId;

      // Get product details from chat document
      final myProductsMap =
          isInitiator ? _currentChat!.initiatorProducts : _currentChat!.recipientProducts;
      final theirProductsMap =
          isInitiator ? _currentChat!.recipientProducts : _currentChat!.initiatorProducts;

      if (myProductsMap != null &&
          myProductsMap.isNotEmpty &&
          theirProductsMap != null &&
          theirProductsMap.isNotEmpty) {
        // Get first product from each side for AI (simplified)
        final myProductId = myProductsMap.keys.first;
        final theirProductId = theirProductsMap.keys.first;

        final myProductData = myProductsMap[myProductId] as Map<String, dynamic>;
        final theirProductData = theirProductsMap[theirProductId] as Map<String, dynamic>;

        // Create ProductModel objects from stored data
        setState(() {
          _userProduct = ProductModel(
            id: myProductId,
            userId: currentUserId,
            name: myProductData['name'] as String,
            details: myProductData['details'] as String,
            imageUrls: List<String>.from(myProductData['imageUrls'] as List),
            price: (myProductData['price'] as num).toDouble(),
            condition: myProductData['condition'] as String,
            brand: myProductData['brand'] as String? ?? '',
            ageInMonths: (myProductData['ageInMonths'] as num?)?.toInt() ?? 0,
            isActive: true,
            isTraded: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          _otherUserProduct = ProductModel(
            id: theirProductId,
            userId: widget.otherUserId,
            name: theirProductData['name'] as String,
            details: theirProductData['details'] as String,
            imageUrls: List<String>.from(theirProductData['imageUrls'] as List),
            price: (theirProductData['price'] as num).toDouble(),
            condition: theirProductData['condition'] as String,
            brand: theirProductData['brand'] as String? ?? '',
            ageInMonths: (theirProductData['ageInMonths'] as num?)?.toInt() ?? 0,
            isActive: true,
            isTraded: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        });

        print(
            '✅ SUCCESS [ChatDetail]: Products loaded from chat - My: ${_userProduct!.name}, Their: ${_otherUserProduct!.name}');
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to load products from chat: $e');
    }
  }

  Future<void> _loadTradeData() async {
    print('🔄 DEBUG [ChatDetail]: Loading trade data...');
    setState(() => _isLoading = true);

    try {
      final currentUserId = _authController.firebaseUser.value!.uid;
      final trade = await _tradeService.getTradeByChatId(widget.chatId, currentUserId);
      if (trade != null) {
        print('✅ SUCCESS [ChatDetail]: Trade found - ID: ${trade.id}');
        if (mounted) {
          setState(() {
            _trade = trade;
            _currentUserConfirmed = trade.initiatorUserId == currentUserId
                ? trade.initiatorConfirmed
                : trade.recipientConfirmed;
          });
        }
        print(
            '✅ SUCCESS [ChatDetail]: Trade status - Current user confirmed: $_currentUserConfirmed');

        // Load product details for AI negotiation coach
        await _loadProducts(trade, currentUserId);
      } else {
        print('💬 DEBUG [ChatDetail]: No trade associated with this chat');
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to load trade data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProducts(TradeModel trade, String currentUserId) async {
    try {
      print('📦 DEBUG [ChatDetail]: Loading product details for AI...');

      // Determine which products belong to which user
      final isInitiator = trade.initiatorUserId == currentUserId;
      final myProductIds = isInitiator ? trade.initiatorProductIds : trade.recipientProductIds;
      final theirProductIds = isInitiator ? trade.recipientProductIds : trade.initiatorProductIds;

      if (myProductIds.isNotEmpty && theirProductIds.isNotEmpty) {
        // Load first product from each side (simplified for now)
        final myProductDoc =
            await _firebaseService.firestore.collection('products').doc(myProductIds.first).get();

        final theirProductDoc = await _firebaseService.firestore
            .collection('products')
            .doc(theirProductIds.first)
            .get();

        if (myProductDoc.exists && theirProductDoc.exists) {
          setState(() {
            _userProduct = ProductModel.fromFirestore(myProductDoc);
            _otherUserProduct = ProductModel.fromFirestore(theirProductDoc);
          });
          print(
              '✅ SUCCESS [ChatDetail]: Products loaded - My: ${_userProduct!.name}, Their: ${_otherUserProduct!.name}');
        }
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to load products: $e');
      // Non-critical, AI will work with limited data
    }
  }

  Future<void> _getAINegotiationHelp() async {
    print('🤖 DEBUG [ChatDetail]: User requested AI negotiation help');

    setState(() => _isLoadingAI = true);

    try {
      // Get all messages
      final messages = await _chatService.getChatMessages(widget.chatId).first;

      if (messages.isEmpty) {
        Get.snackbar(
          'No Messages Yet',
          'Start the conversation first to get AI help',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstants.primaryColor.withOpacity(0.9),
          colorText: Colors.white,
        );
        setState(() => _isLoadingAI = false);
        return;
      }

      // Convert to AI format
      final currentUserId = _authController.firebaseUser.value!.uid;
      final chatTranscript = messages.reversed
          .map((msg) => ChatMessageAI(
                message: msg.text ?? '',
                isCurrentUser: msg.senderId == currentUserId,
              ))
          .toList();

      print('💬 DEBUG [ChatDetail]: Prepared ${chatTranscript.length} messages for AI');

      // Check if we have product details
      if (_userProduct == null || _otherUserProduct == null) {
        setState(() => _isLoadingAI = false);
        Get.snackbar(
          'Product Details Missing',
          'Product information is still loading. Please try again in a moment.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstants.primaryColor.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      // Prepare item info with detailed product data
      print('📦 DEBUG [ChatDetail]: Using detailed product info from chat');
      final userItem = ItemInfoAI(
        title: _userProduct!.name,
        description: _userProduct!.details,
        estimatedValue: _userProduct!.price,
        condition: _userProduct!.condition,
      );
      final otherUserItem = ItemInfoAI(
        title: _otherUserProduct!.name,
        description: _otherUserProduct!.details,
        estimatedValue: _otherUserProduct!.price,
        condition: _otherUserProduct!.condition,
      );

      // Call AI service
      print('🚀 DEBUG [ChatDetail]: Calling AI service...');
      final suggestion = await _aiService.getNegotiationCoachSuggestion(
        chatTranscript: chatTranscript,
        userItem: userItem,
        otherUserItem: otherUserItem,
        currentOffer: OfferInfoAI(
          cashAdjustment: 0,
          status: 'negotiating',
        ),
      );

      print('✅ DEBUG [ChatDetail]: AI suggestion received successfully');
      // Show suggestion dialog
      _showAISuggestionDialog(suggestion);
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to get AI help: $e');
      String errorMessage = e.toString().replaceAll('Exception: ', '');

      // Make error messages more user-friendly
      if (errorMessage.contains('timeout') || errorMessage.contains('took too long')) {
        errorMessage = 'AI is taking longer than expected. Please try again.';
      } else if (errorMessage.contains('connection') || errorMessage.contains('network')) {
        errorMessage = 'No internet connection. Please check your network.';
      } else if (errorMessage.contains('404') || errorMessage.contains('not found')) {
        errorMessage = 'AI service is currently unavailable. Please try again later.';
      }

      Get.snackbar(
        'AI Service Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  void _showAISuggestionDialog(NegotiationSuggestion suggestion) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'AI Negotiation Coach',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Suggested Message
              const Text(
                'Suggested Message:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
                ),
                child: Text(
                  suggestion.suggestionPhrase,
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(height: 16),

              // Cash Adjustment
              const Text(
                'Suggested Adjustment:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                suggestion.formattedCashAdjustment,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: suggestion.suggestedCashAdjustment == 0
                      ? Colors.green
                      : AppConstants.primaryColor,
                ),
              ),

              const SizedBox(height: 16),

              // Explanation
              const Text(
                'Why This Works:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                suggestion.explanation,
                style: const TextStyle(fontSize: 13),
              ),

              if (suggestion.negotiationTips.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Negotiation Tips:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...suggestion.negotiationTips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              setState(() {
                _messageController.text = suggestion.suggestionPhrase;
              });
              // Optionally focus the text field
              FocusScope.of(context).requestFocus(FocusNode());
            },
            icon: const Icon(Icons.send),
            label: const Text('Use This'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      print('⚠️ WARNING [ChatDetail]: Attempted to send empty message');
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Clear text field immediately for better UX
    _messageController.clear();

    print(
        '💬 DEBUG [ChatDetail]: Sending text message: "${text.substring(0, text.length > 20 ? 20 : text.length)}..."');
    setState(() => _isSending = true);

    try {
      final currentUser = _authController.userModel.value;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print('💬 DEBUG [ChatDetail]: Sender: ${currentUser.displayName}');

      await _chatService.sendTextMessage(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown',
        senderPhotoUrl: currentUser.profilePhotoUrl,
        text: text,
        recipientId: widget.otherUserId,
      );

      print('✅ SUCCESS [ChatDetail]: Message sent successfully');
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to send message');
      print('❌ ERROR [ChatDetail]: Error details: $e');

      String userMessage = 'Unable to send message';
      if (e.toString().contains('permission')) {
        userMessage = 'You don\'t have permission to send messages';
      } else if (e.toString().contains('network')) {
        userMessage = 'No internet connection';
      }

      Get.snackbar(
        'Message Failed',
        userMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    print('📷 DEBUG [ChatDetail]: Opening image picker');

    // Show action sheet
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
                'Send Image',
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

    if (source == null) {
      print('📷 DEBUG [ChatDetail]: Image picker cancelled');
      return;
    }

    print(
        '📷 DEBUG [ChatDetail]: Selected source: ${source == ImageSource.camera ? "Camera" : "Gallery"}');

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        print('📷 DEBUG [ChatDetail]: Image selected: ${image.path}');
        setState(() => _isSending = true);

        final currentUser = _authController.userModel.value;

        if (currentUser == null) {
          throw Exception('User not logged in');
        }

        print('📷 DEBUG [ChatDetail]: Uploading image...');
        await _chatService.sendImageMessage(
          chatId: widget.chatId,
          senderId: currentUser.uid,
          senderName: currentUser.displayName ?? 'Unknown',
          senderPhotoUrl: currentUser.profilePhotoUrl,
          imageFile: File(image.path),
          recipientId: widget.otherUserId,
        );

        print('✅ SUCCESS [ChatDetail]: Image sent successfully');
        setState(() => _isSending = false);
      } else {
        print('📷 DEBUG [ChatDetail]: No image selected');
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to send image');
      print('❌ ERROR [ChatDetail]: Error details: $e');

      setState(() => _isSending = false);

      String userMessage = 'Unable to send image';
      if (e.toString().contains('permission')) {
        userMessage = 'Camera/gallery permission denied';
      } else if (e.toString().contains('storage')) {
        userMessage = 'Storage permission denied';
      } else if (e.toString().contains('network')) {
        userMessage = 'No internet connection';
      }

      Get.snackbar(
        'Image Failed',
        userMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _confirmTrade() async {
    if (_trade == null) {
      Get.snackbar(
        'No Trade',
        'No active trade found for this chat',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_currentUserConfirmed) {
      Get.snackbar(
        'Already Confirmed',
        'You have already confirmed this trade',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Animate tick
    _tickController.forward().then((_) => _tickController.reverse());

    setState(() => _isLoading = true);

    try {
      final currentUser = _authController.userModel.value!;

      await _tradeService.confirmTrade(
        tradeId: _trade!.id,
        userId: currentUser.uid,
        otherUserId: widget.otherUserId,
        userName: currentUser.displayName ?? 'Unknown',
      );

      setState(() => _currentUserConfirmed = true);

      // Reload trade data
      await _loadTradeData();

      // Check if both confirmed
      if (_trade!.isBothConfirmed) {
        // Navigate to finalization
        Get.to(() => TradeFinalizationView(trade: _trade!));
      } else {
        Get.snackbar(
          'Confirmed!',
          'Waiting for ${widget.otherUserName} to confirm',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstants.successColor.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ DEBUG: Error confirming trade: $e');
      Get.snackbar(
        'Error',
        'Failed to confirm trade',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCompleteTradeDialog() async {
    print('🎉 DEBUG [ChatDetail]: Showing complete trade dialog');

    final currentUserId = _authController.firebaseUser.value!.uid;

    // Check if this is a payment request scenario (awaiting payment from payer)
    if (_trade?.negotiationStatus == 'awaiting_payment' && _trade?.payingUserId == currentUserId) {
      // Current user is the payer and there's a payment request
      await _respondToPaymentRequest();
      return;
    }

    // Determine if payment is needed and who pays
    final priceDiff = _trade?.priceDifference ?? 0;
    final payingUserId = _trade?.payingUserId;
    final hasPayment = priceDiff >= 10 && payingUserId != null;

    print('💰 DEBUG [ChatDetail]: Price difference: \$$priceDiff, Payment needed: $hasPayment');

    // If no payment needed or price difference is small, direct swap
    if (!hasPayment) {
      await _completeDirectSwap();
      return;
    }

    // Payment is needed - check who is the current user
    if (currentUserId == payingUserId) {
      // Current user is the PAYER - they can't initiate completion
      Get.snackbar(
        'Waiting for Payment Request',
        'The other party needs to send you a payment request to complete this trade',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.systemGray4,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Current user is the PAYEE - they can request payment
    await _requestPaymentFromPayer();
  }

  /// Handle direct swap (no money involved)
  Future<void> _completeDirectSwap() async {
    print('✅ DEBUG [ChatDetail]: Completing direct swap (no payment)');

    // Show location reminder
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('Complete Trade'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before completing:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Share your meetup location')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Agree on time and place')),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Ready to complete?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Complete trade immediately
    await _completeTrade();
  }

  /// Payee requests payment from payer
  Future<void> _requestPaymentFromPayer() async {
    print('💳 DEBUG [ChatDetail]: Payee requesting payment from payer');

    // Show dialog to enter agreed amount
    final TextEditingController amountController = TextEditingController();
    final suggestedAmount = _trade?.priceDifference ?? 0;
    amountController.text = suggestedAmount.toStringAsFixed(2);

    final confirmedAmount = await Get.dialog<double>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.attach_money, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('Request Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the amount you both agreed on:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                hintText: 'e.g., ${suggestedAmount.toStringAsFixed(2)}',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Suggested: \$${suggestedAmount.toStringAsFixed(2)} (based on price difference)',
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.systemGray,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                Get.snackbar(
                  'Invalid Amount',
                  'Please enter a valid amount',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppConstants.errorColor.withOpacity(0.9),
                  colorText: Colors.white,
                );
                return;
              }
              Get.back(result: amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );

    if (confirmedAmount == null) return;

    print('💵 DEBUG [ChatDetail]: Payment request amount: \$$confirmedAmount');

    // Update trade with payment request
    await _firebaseService.firestore.collection('trades').doc(_trade!.id).update({
      'negotiationStatus': 'awaiting_payment',
      'agreedAmount': confirmedAmount,
      'completionRequestedBy': _authController.firebaseUser.value!.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Send notification to payer
    await _notificationService.sendNotification(
      userId: _trade!.payingUserId!,
      type: 'payment_request',
      title: 'Payment Request from ${_authController.userModel.value?.displayName}',
      message: 'Requesting \$${confirmedAmount.toStringAsFixed(2)} to complete the trade',
      data: {
        'tradeId': _trade!.id,
        'chatId': widget.chatId,
        'amount': confirmedAmount,
        'payeeId': _authController.firebaseUser.value!.uid,
        'payeeName': _authController.userModel.value?.displayName,
      },
    );

    Get.snackbar(
      'Request Sent',
      'Payment request sent successfully',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
    );

    print('✅ DEBUG [ChatDetail]: Payment request sent successfully');
  }

  /// Payer responds to payment request
  Future<void> _respondToPaymentRequest() async {
    print('💳 DEBUG [ChatDetail]: Payer responding to payment request');

    final amount = _trade?.agreedAmount ?? 0;
    final payeeName = widget.otherUserName;

    // Show payment request dialog
    final response = await Get.dialog<String>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('Payment Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$payeeName is requesting:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'How would you like to proceed?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: 'decline'),
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: 'pay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept & Pay'),
          ),
        ],
      ),
    );

    if (response == 'decline') {
      // Decline payment request
      await _firebaseService.firestore.collection('trades').doc(_trade!.id).update({
        'negotiationStatus': 'negotiating',
        'agreedAmount': null,
        'completionRequestedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify payee
      await _notificationService.sendNotification(
        userId: widget.otherUserId,
        type: 'payment_declined',
        title: 'Payment Declined',
        message: '${_authController.userModel.value?.displayName} wants to continue negotiating',
        data: {
          'tradeId': _trade!.id,
          'chatId': widget.chatId,
        },
      );

      Get.snackbar(
        'Request Declined',
        'You can continue negotiating',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.systemGray4,
      );

      return;
    }

    if (response == 'pay') {
      // Process payment
      await _processPaymentAndComplete(amount);
    }
  }

  /// Process payment and complete trade (ONLY completes if payment succeeds)
  Future<void> _processPaymentAndComplete(double amount) async {
    print('💳 DEBUG [ChatDetail]: Processing payment for \$$amount');

    final currentUserId = _authController.firebaseUser.value!.uid;
    final payerUserId = currentUserId;
    final payeeUserId = widget.otherUserId;

    // Show processing dialog
    Get.dialog(
      const PaymentProcessingDialog(),
      barrierDismissible: false,
    );

    try {
      // Get user details for transaction
      final payerDoc = await _firebaseService.firestore.collection('users').doc(payerUserId).get();
      final payeeDoc = await _firebaseService.firestore.collection('users').doc(payeeUserId).get();

      final payerData = payerDoc.data();
      final payeeData = payeeDoc.data();

      // Create transaction record
      final transaction = await _transactionService.createTransaction(
        tradeId: _trade!.id,
        payerUserId: payerUserId,
        payeeUserId: payeeUserId,
        amount: amount,
        paymentMethod: 'nessie',
        description:
            'Trade payment for ${_userProduct?.name ?? 'product'} ↔ ${_otherUserProduct?.name ?? 'product'}',
        payerName: payerData?['displayName'],
        payeeName: payeeData?['displayName'],
        payerPhoto: payerData?['profilePhotoUrl'],
        payeePhoto: payeeData?['profilePhotoUrl'],
      );

      // Update transaction to processing
      await _transactionService.updateTransactionStatus(
        transactionId: transaction.id,
        status: 'processing',
      );

      // Process payment through Nessie API
      final paymentResult = await _nessieService.makePayment(
        payerUserId: payerUserId,
        payeeUserId: payeeUserId,
        amount: amount,
        description: 'BarterBrAIn Trade Payment',
      );

      // Close processing dialog
      Get.back();

      if (paymentResult['success'] == true) {
        print('✅ DEBUG [ChatDetail]: Payment successful!');

        // Update transaction to completed
        await _transactionService.updateTransactionStatus(
          transactionId: transaction.id,
          status: 'completed',
          nessieTransferId: paymentResult['transferId'],
        );

        // Show success animation
        await Get.dialog(
          PaymentSuccessDialog(
            amount: amount,
            onDone: () => Get.back(),
          ),
          barrierDismissible: false,
        );

        // NOW complete the trade (only after payment success)
        await _completeTrade();
      } else {
        print('❌ DEBUG [ChatDetail]: Payment failed');

        // Update transaction to failed
        await _transactionService.updateTransactionStatus(
          transactionId: transaction.id,
          status: 'failed',
          errorMessage: paymentResult['error'] ?? 'Payment failed',
        );

        Get.snackbar(
          'Payment Failed',
          paymentResult['error'] ?? 'Unable to process payment. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstants.errorColor.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        // Keep trade in awaiting_payment status so they can try again
        print('⚠️ DEBUG [ChatDetail]: Trade remains in awaiting_payment status');
      }
    } catch (e) {
      Get.back(); // Close processing dialog
      print('❌ ERROR [ChatDetail]: Error processing payment: $e');

      Get.snackbar(
        'Error',
        'Failed to process payment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _completeTrade() async {
    print('✅ DEBUG [ChatDetail]: Completing trade...');
    setState(() => _isLoading = true);

    try {
      // If trade doesn't exist (permission error), create it now
      if (_trade == null && _currentChat != null) {
        print('⚠️ DEBUG [ChatDetail]: No trade found, creating from chat data...');

        final currentUserId = _authController.firebaseUser.value!.uid;
        final initiatorProductIds = _currentChat!.initiatorProducts?.keys.toList() ?? [];
        final recipientProductIds = _currentChat!.recipientProducts?.keys.toList() ?? [];

        if (initiatorProductIds.isEmpty || recipientProductIds.isEmpty) {
          Get.snackbar(
            'Error',
            'Product information is missing. Please restart the chat.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstants.errorColor.withOpacity(0.9),
            colorText: Colors.white,
          );
          return;
        }

        // Create trade
        _trade = await _tradeService.createTrade(
          chatId: widget.chatId,
          initiatorUserId: _currentChat!.participantIds.first,
          recipientUserId: _currentChat!.participantIds.last,
          initiatorProductIds: initiatorProductIds,
          recipientProductIds: recipientProductIds,
        );

        print('✅ DEBUG [ChatDetail]: Trade created: ${_trade!.id}');
      } else if (_trade == null) {
        print('❌ ERROR [ChatDetail]: No trade or chat data found');
        Get.snackbar(
          'Error',
          'Trade information not found. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstants.errorColor.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      // Update trade status
      await _tradeService.updateTradeStatus(
        tradeId: _trade!.id,
        status: 'completed',
        completedAt: DateTime.now(),
      );

      print('✅ SUCCESS [ChatDetail]: Trade marked as completed');

      // Calculate sustainability impact
      await _calculateAndShowSustainabilityImpact();

      // Send system message about trade completion
      await _chatService.sendSystemMessage(
        chatId: widget.chatId,
        systemMessage: '🎉 Trade Completed Successfully!\n\n'
            'Both parties have agreed to complete this trade. '
            'Please coordinate in person to exchange the items.\n\n'
            '📍 Share your meetup location in the chat if you haven\'t already.',
      );

      // Reload trade data to update UI (only if widget is still mounted)
      if (mounted) {
        setState(() {
          _trade = _trade!.copyWith(status: 'completed');
        });

        Get.snackbar(
          'Trade Completed! 🎉',
          'Coordinate with the other user to exchange items',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to complete trade: $e');
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to complete trade. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstants.errorColor.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _calculateAndShowSustainabilityImpact() async {
    try {
      print('🌱 DEBUG [ChatDetail]: Calculating sustainability impact...');

      // Get product details for recipient's product (the main item being traded for)
      if (_otherUserProduct == null || _trade == null) {
        print('⚠️ DEBUG [ChatDetail]: Missing product or trade data, skipping sustainability');
        return;
      }

      final itemName = _otherUserProduct!.name;
      final estimatedNewCost =
          _otherUserProduct!.price * 2.0; // Estimate new price as 2x current value
      final proposerItemValue = _userProduct?.price ?? 0.0;
      final proposerCash = _trade!.paymentAmount ?? 0.0;

      print('📦 DEBUG [ChatDetail]: Item: $itemName');
      print('💰 DEBUG [ChatDetail]: Estimated new cost: \$$estimatedNewCost');
      print('💰 DEBUG [ChatDetail]: Your item value: \$$proposerItemValue');
      print('💵 DEBUG [ChatDetail]: Cash: \$$proposerCash');

      // Call AI service
      final sustainabilityImpact = await _aiService.getSustainabilityImpact(
        tradeId: _trade!.id,
        estimatedNewCost: estimatedNewCost,
        proposerItemValue: proposerItemValue,
        proposerCash: proposerCash,
        itemName: itemName,
      );

      if (sustainabilityImpact != null && sustainabilityImpact.isNotEmpty) {
        print('✅ DEBUG [ChatDetail]: Sustainability impact calculated: $sustainabilityImpact');

        // Update trade with sustainability impact
        await _firebaseService.firestore
            .collection('trades')
            .doc(_trade!.id)
            .update({'sustainabilityImpact': sustainabilityImpact});

        // Update local state (only if widget is still mounted)
        if (mounted) {
          setState(() {
            _trade = _trade!.copyWith(sustainabilityImpact: sustainabilityImpact);
          });

          // Show beautiful sustainability dialog
          _showSustainabilityDialog(sustainabilityImpact);
        }
      } else {
        print('⚠️ DEBUG [ChatDetail]: No sustainability impact calculated');
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Error calculating sustainability: $e');
      // Don't show error to user - sustainability is optional
    }
  }

  void _showSustainabilityDialog(String impact) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Sustainability Impact! 🌱',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Impact message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  impact,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _endChat() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End Chat'),
        content:
            const Text('Are you sure you want to end this conversation? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('End Chat', style: TextStyle(color: AppConstants.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _authController.userModel.value!;

      await _chatService.endChat(
        chatId: widget.chatId,
        endedBy: currentUser.uid,
        reason: 'not_interested',
        otherUserId: widget.otherUserId,
        currentUserName: currentUser.displayName ?? 'Unknown',
      );

      Get.back();
      Get.snackbar(
        'Chat Ended',
        'This conversation has been closed',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ DEBUG: Error ending chat: $e');
      Get.snackbar(
        'Error',
        'Failed to end chat',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUserPhoto != null
                  ? CachedNetworkImageProvider(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? Text(widget.otherUserName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
        actions: [
          // Complete Trade Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: (_trade?.isCompleted ?? false) ? Colors.grey : Colors.green,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.check_circle,
                color: (_trade?.isCompleted ?? false) ? Colors.white54 : Colors.white,
              ),
              onPressed: (_trade?.isCompleted ?? false) ? null : _showCompleteTradeDialog,
              tooltip:
                  (_trade?.isCompleted ?? false) ? 'Trade Already Completed' : 'Complete Trade',
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Trade Completed Banner
            if (_trade?.isCompleted ?? false)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade400],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trade Completed! 🎉',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Coordinate your meetup below',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sustainability Impact Button
                    if (_trade?.sustainabilityImpact != null &&
                        _trade!.sustainabilityImpact!.isNotEmpty)
                      IconButton(
                        onPressed: () => _showSustainabilityDialog(_trade!.sustainabilityImpact!),
                        icon: const Icon(Icons.eco, color: Colors.white, size: 24),
                        tooltip: 'View Sustainability Impact',
                      ),
                  ],
                ),
              ),

            // Messages
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getChatMessages(widget.chatId),
                builder: (context, snapshot) {
                  print(
                      '💬 DEBUG [ChatDetail]: Messages stream state: ${snapshot.connectionState}');

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('💬 DEBUG [ChatDetail]: Loading messages...');
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading conversation...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error.toString();
                    print('❌ ERROR [ChatDetail]: Failed to load messages');
                    print('❌ ERROR [ChatDetail]: Error details: $error');

                    String userMessage = 'Unable to load messages';
                    String userHint = 'Please check your connection';

                    if (error.contains('permission') || error.contains('Permission')) {
                      userMessage = 'Permission Denied';
                      userHint = 'You may not have access to this chat';
                    }

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 60, color: AppConstants.errorColor),
                            const SizedBox(height: 16),
                            Text(
                              userMessage,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userHint,
                              style: const TextStyle(
                                color: AppConstants.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Go Back'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print('💬 DEBUG [ChatDetail]: No messages yet');
                    return const Center(
                      child: Text(
                        'No messages yet.\nStart the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppConstants.textSecondary),
                      ),
                    );
                  }

                  final messages = snapshot.data!;
                  print('✅ SUCCESS [ChatDetail]: Loaded ${messages.length} messages');

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _authController.firebaseUser.value!.uid;
                      final showAvatar = index == messages.length - 1 ||
                          messages[index + 1].senderId != message.senderId;

                      return _buildMessageBubble(message, isMe, showAvatar);
                    },
                  );
                },
              ),
            ),

            // Emoji Picker
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _messageController.text += emoji.emoji;
                  },
                ),
              ),

            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  /// Check if message contains a map/location URL
  bool _isLocationMessage(String? text) {
    if (text == null) return false;
    final lowerText = text.toLowerCase();
    return lowerText.contains('maps.google.com') ||
        lowerText.contains('goo.gl/maps') ||
        lowerText.contains('maps.apple.com') ||
        lowerText.contains('google.com/maps') ||
        lowerText.contains('apple.com/maps') ||
        (lowerText.contains('http') && lowerText.contains('map'));
  }

  /// Extract URL from message text
  String? _extractUrl(String text) {
    final urlPattern = RegExp(
      r'(https?://[^\s]+)',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(text);
    return match?.group(0);
  }

  /// Launch map URL
  Future<void> _launchMapUrl(String text) async {
    try {
      final url = _extractUrl(text);
      if (url == null) {
        print('⚠️ DEBUG [ChatDetail]: No URL found in message');
        return;
      }

      print('🗺️ DEBUG [ChatDetail]: Attempting to launch URL: $url');
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ DEBUG [ChatDetail]: URL launched successfully');
      } else {
        print('❌ DEBUG [ChatDetail]: Could not launch URL: $url');
        Get.snackbar(
          'Error',
          'Could not open map link',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppConstants.errorColor.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ DEBUG [ChatDetail]: Error launching URL: $e');
      Get.snackbar(
        'Error',
        'Failed to open map link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.errorColor.withOpacity(0.9),
        colorText: Colors.white,
      );
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool showAvatar) {
    if (message.isSystemMessage) {
      return _buildSystemMessage(message);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherUserPhoto != null
                  ? CachedNetworkImageProvider(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? Text(widget.otherUserName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 12))
                  : null,
            ),
          if (!isMe && !showAvatar) const SizedBox(width: 32),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppConstants.primaryColor : AppConstants.systemGray6,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isImageMessage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (_isLocationMessage(message.text))
                    GestureDetector(
                      onTap: () => _launchMapUrl(message.text!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: isMe ? Colors.white : AppConstants.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'View Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isMe ? Colors.white : AppConstants.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.text ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: isMe ? Colors.white.withOpacity(0.9) : AppConstants.systemGray,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      message.text ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: isMe ? Colors.white : AppConstants.tertiaryColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : AppConstants.systemGray2,
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

  Widget _buildSystemMessage(MessageModel message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppConstants.systemGray6,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.systemMessage ?? '',
          style: const TextStyle(
            fontSize: 14,
            color: AppConstants.systemGray,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Emoji Button
              IconButton(
                icon: Icon(
                  _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  color: AppConstants.primaryColor,
                ),
                onPressed: () {
                  setState(() => _showEmojiPicker = !_showEmojiPicker);
                },
              ),

              // Image Button
              IconButton(
                icon: const Icon(Icons.image_outlined, color: AppConstants.primaryColor),
                onPressed: _isSending ? null : _sendImage,
              ),

              // Text Input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppConstants.systemGray6,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  onTap: () {
                    if (_showEmojiPicker) {
                      setState(() => _showEmojiPicker = false);
                    }
                  },
                ),
              ),

              // Gemini AI Assistant Button
              Container(
                margin: const EdgeInsets.only(left: 4, right: 4),
                decoration: BoxDecoration(
                  gradient: (_trade?.isCompleted ?? false)
                      ? const LinearGradient(
                          colors: [Colors.grey, Colors.grey],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF4285F4), Color(0xFF34A853)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  shape: BoxShape.circle,
                ),
                child: _isLoadingAI
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          Icons.auto_awesome,
                          color: (_trade?.isCompleted ?? false) ? Colors.white54 : Colors.white,
                          size: 20,
                        ),
                        onPressed: (_trade?.isCompleted ?? false) || _isLoadingAI
                            ? null
                            : _getAINegotiationHelp,
                        tooltip: (_trade?.isCompleted ?? false)
                            ? 'AI Not Available - Trade Completed'
                            : 'Gemini AI Negotiation Coach',
                      ),
              ),

              // Send Button
              IconButton(
                icon: Icon(
                  _isSending ? Icons.hourglass_empty : Icons.send,
                  color: AppConstants.primaryColor,
                ),
                onPressed: _isSending ? null : _sendTextMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';

    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
