import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/message_model.dart';
import '../../models/trade_model.dart';
import '../../services/chat_service.dart';
import '../../services/trade_service.dart';
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

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _showEmojiPicker = false;
  bool _isLoading = false;
  bool _isSending = false;

  TradeModel? _trade;
  bool _currentUserConfirmed = false;

  late AnimationController _tickController;
  late Animation<double> _tickAnimation;

  @override
  void initState() {
    super.initState();
    print('💬 DEBUG [ChatDetail]: Initializing chat detail view');
    print('💬 DEBUG [ChatDetail]: Chat ID: ${widget.chatId}');
    print('💬 DEBUG [ChatDetail]: Other user: ${widget.otherUserName} (${widget.otherUserId})');
    
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

  Future<void> _loadTradeData() async {
    print('🔄 DEBUG [ChatDetail]: Loading trade data...');
    setState(() => _isLoading = true);

    try {
      final trade = await _tradeService.getTradeByChatId(widget.chatId);
      if (trade != null) {
        print('✅ SUCCESS [ChatDetail]: Trade found - ID: ${trade.id}');
        final currentUserId = _authController.firebaseUser.value!.uid;
        setState(() {
          _trade = trade;
          _currentUserConfirmed = trade.initiatorUserId == currentUserId
              ? trade.initiatorConfirmed
              : trade.recipientConfirmed;
        });
        print('✅ SUCCESS [ChatDetail]: Trade status - Current user confirmed: $_currentUserConfirmed');
      } else {
        print('💬 DEBUG [ChatDetail]: No trade associated with this chat');
      }
    } catch (e) {
      print('❌ ERROR [ChatDetail]: Failed to load trade data: $e');
      // Don't show error to user - trade data is optional
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      print('⚠️ WARNING [ChatDetail]: Attempted to send empty message');
      return;
    }

    print('💬 DEBUG [ChatDetail]: Sending text message: "${text.substring(0, text.length > 20 ? 20 : text.length)}..."');
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

    print('📷 DEBUG [ChatDetail]: Selected source: ${source == ImageSource.camera ? "Camera" : "Gallery"}');

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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _endChat() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('End Chat'),
        content: const Text('Are you sure you want to end this conversation? This cannot be undone.'),
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
          IconButton(
            icon: const Icon(Icons.not_interested),
            onPressed: _endChat,
            tooltip: 'Not Interested',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                print('💬 DEBUG [ChatDetail]: Messages stream state: ${snapshot.connectionState}');
                
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
                          const Icon(Icons.error_outline, size: 60, color: AppConstants.errorColor),
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
              child:               EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text += emoji.emoji;
                },
              ),
            ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
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
                  ? Text(widget.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 12))
                  : null,
            ),
          if (!isMe && !showAvatar) const SizedBox(width: 32),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppConstants.primaryColor
                    : AppConstants.systemGray6,
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

              // Send Button
              IconButton(
                icon: Icon(
                  _isSending ? Icons.hourglass_empty : Icons.send,
                  color: AppConstants.primaryColor,
                ),
                onPressed: _isSending ? null : _sendTextMessage,
              ),

              // Green Tick (Confirm Trade)
              if (_trade != null && !_trade!.isCompleted)
                ScaleTransition(
                  scale: _tickAnimation,
                  child: IconButton(
                    icon: Icon(
                      _currentUserConfirmed ? Icons.check_circle : Icons.check_circle_outline,
                      color: _currentUserConfirmed ? Colors.green : AppConstants.primaryColor,
                      size: 28,
                    ),
                    onPressed: _isLoading ? null : _confirmTrade,
                  ),
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

