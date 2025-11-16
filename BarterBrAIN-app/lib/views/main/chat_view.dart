import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import '../chat/chat_detail_view.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    print('💬 DEBUG [ChatView]: Building chat view');
    
    final authController = Get.find<AuthController>();
    final chatService = Get.find<ChatService>();
    final currentUserId = authController.firebaseUser.value?.uid ?? '';
    
    print('💬 DEBUG [ChatView]: Current user ID: $currentUserId');

    if (currentUserId.isEmpty) {
      print('❌ ERROR [ChatView]: No user logged in');
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 60, color: AppConstants.errorColor),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view messages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to be logged in to access your chats',
                style: TextStyle(color: AppConstants.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                Text(
                  'Messages',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Unread count badge
                StreamBuilder<List<ChatModel>>(
                  stream: chatService.getUserChats(currentUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final unreadCount = snapshot.data!
                        .where((chat) => chat.getUnreadCount(currentUserId) > 0)
                        .length;

                    if (unreadCount == 0) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unreadCount unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Chat List
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: chatService.getUserChats(currentUserId),
              builder: (context, snapshot) {
                print('💬 DEBUG [ChatView]: Stream state: ${snapshot.connectionState}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('💬 DEBUG [ChatView]: Loading chats...');
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your messages...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  print('❌ ERROR [ChatView]: Failed to load chats');
                  print('❌ ERROR [ChatView]: Error details: $error');
                  
                  // User-friendly error message
                  String userMessage = 'Unable to load messages';
                  String userHint = 'Please check your internet connection and try again';
                  
                  if (error.contains('permission') || error.contains('Permission')) {
                    userMessage = 'Permission Error';
                    userHint = 'You may not have access to view messages. Please contact support.';
                  } else if (error.contains('network') || error.contains('Network')) {
                    userMessage = 'Connection Error';
                    userHint = 'Please check your internet connection';
                  }
                  
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 60, color: AppConstants.errorColor),
                          const SizedBox(height: 16),
                          Text(
                            userMessage,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userHint,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppConstants.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Trigger rebuild
                              (context as Element).markNeedsBuild();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
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
                  print('💬 DEBUG [ChatView]: No chats found');
                  return _buildEmptyState(context);
                }

                final chats = snapshot.data!;
                print('✅ SUCCESS [ChatView]: Loaded ${chats.length} chats');

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100), // Space for nav bar
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _buildChatTile(context, chat, currentUserId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Space for nav bar
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'No Messages',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
              child: Text(
                'Your conversations will appear here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatModel chat, String currentUserId) {
    final otherUserName = chat.getOtherParticipantName(currentUserId);
    final otherUserPhoto = chat.getOtherParticipantPhoto(currentUserId);
    final otherUserId = chat.getOtherParticipantId(currentUserId);
    final unreadCount = chat.getUnreadCount(currentUserId);
    final isEnded = chat.isEnded;

    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppConstants.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Delete Chat'),
            content: const Text('Are you sure you want to delete this conversation?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: const Text('Delete', style: TextStyle(color: AppConstants.errorColor)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        // TODO: Add delete chat functionality to ChatService
        Get.snackbar(
          'Chat Deleted',
          'Conversation removed',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('💬 DEBUG [ChatView]: Opening chat: ${chat.id}');
            print('💬 DEBUG [ChatView]: Other user: $otherUserName ($otherUserId)');
            
            try {
              // Mark as read when opening
              final chatService = Get.find<ChatService>();
              chatService.markMessagesAsRead(chatId: chat.id, userId: currentUserId);
              print('✅ SUCCESS [ChatView]: Messages marked as read');

              // Navigate to chat detail
              Get.to(() => ChatDetailView(
                    chatId: chat.id,
                    otherUserId: otherUserId,
                    otherUserName: otherUserName,
                    otherUserPhoto: otherUserPhoto,
                  ));
              print('✅ SUCCESS [ChatView]: Navigated to chat detail');
            } catch (e) {
              print('❌ ERROR [ChatView]: Failed to open chat: $e');
              Get.snackbar(
                'Error',
                'Unable to open this chat. Please try again.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppConstants.errorColor.withOpacity(0.9),
                colorText: Colors.white,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingM,
            ),
            decoration: BoxDecoration(
              color: unreadCount > 0
                  ? AppConstants.primaryColor.withOpacity(0.05)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: AppConstants.systemGray6,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppConstants.systemGray4,
                      backgroundImage: otherUserPhoto != null
                          ? CachedNetworkImageProvider(otherUserPhoto)
                          : null,
                      child: otherUserPhoto == null
                          ? Text(
                              otherUserName[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppConstants.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Chat Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUserName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                color: AppConstants.tertiaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.lastMessageTime != null)
                            Text(
                              _formatTime(chat.lastMessageTime!),
                              style: TextStyle(
                                fontSize: 14,
                                color: unreadCount > 0
                                    ? AppConstants.primaryColor
                                    : AppConstants.systemGray,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (chat.lastMessageSenderId == currentUserId) ...[
                            const Icon(
                              Icons.done_all,
                              size: 16,
                              color: AppConstants.systemGray2,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              isEnded
                                  ? '🔚 Chat ended'
                                  : chat.lastMessage ?? 'No messages yet',
                              style: TextStyle(
                                fontSize: 15,
                                color: unreadCount > 0
                                    ? AppConstants.tertiaryColor
                                    : AppConstants.textSecondary,
                                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEnded)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.block,
                                size: 16,
                                color: AppConstants.errorColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.systemGray3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      // Older - show date
      return '${dateTime.month}/${dateTime.day}/${dateTime.year.toString().substring(2)}';
    }
  }
}
