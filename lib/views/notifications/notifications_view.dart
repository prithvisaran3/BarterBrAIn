import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final notificationService = Get.find<NotificationService>();
    final currentUserId = authController.firebaseUser.value?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Notifications'),
        actions: [
          // Mark all as read
          StreamBuilder<List<NotificationModel>>(
            stream: notificationService.getUserNotifications(currentUserId),
            builder: (context, snapshot) {
              final hasUnread = snapshot.hasData && snapshot.data!.any((n) => !n.isRead);

              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                onPressed: () async {
                  // Mark all as read
                  for (var notification in snapshot.data!) {
                    if (!notification.isRead) {
                      await notificationService.markAsRead(notification.id);
                    }
                  }
                  Get.snackbar(
                    'All Read',
                    'All notifications marked as read',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text('Mark All Read'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notificationService.getUserNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: AppConstants.errorColor),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(
                context,
                notification,
                currentUserId,
                notificationService,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
              Icons.notifications_none,
              size: 60,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'You\'re all caught up! Notifications will appear here',
              style: TextStyle(
                color: AppConstants.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification,
    String currentUserId,
    NotificationService notificationService,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppConstants.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        notificationService.deleteNotification(notification.id);
        Get.snackbar(
          'Deleted',
          'Notification removed',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Mark as read
            if (!notification.isRead) {
              await notificationService.markAsRead(notification.id);
            }

            // Navigate based on type
            _handleNotificationTap(notification);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.transparent
                  : AppConstants.primaryColor.withOpacity(0.05),
              border: const Border(
                bottom: BorderSide(
                  color: AppConstants.systemGray6,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppConstants.tertiaryColor,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.systemGray2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.systemGray3,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'chat_started':
        return Icons.chat_bubble_outline;
      case 'trade_completed':
        return Icons.check_circle_outline;
      case 'chat_ended':
        return Icons.block;
      case 'new_message':
        return Icons.message_outlined;
      case 'payment_received':
        return Icons.payment;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'chat_started':
        return AppConstants.primaryColor;
      case 'trade_completed':
        return Colors.green;
      case 'chat_ended':
        return AppConstants.errorColor;
      case 'new_message':
        return Colors.blue;
      case 'payment_received':
        return Colors.orange;
      default:
        return AppConstants.systemGray;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    print('🔔 DEBUG [Notifications]: Handling tap on ${notification.type} notification');

    // Navigate based on notification type and related IDs
    switch (notification.type) {
      case 'chat_started':
      case 'new_message':
        if (notification.chatId != null) {
          // Navigate to chat - would need to fetch chat details
          // For now, just show a message
          Get.snackbar(
            'Open Chat',
            'Chat feature - ID: ${notification.chatId}',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        break;

      case 'payment_request':
        // Navigate to chat where payment request dialog will show
        if (notification.chatId != null) {
          print('💳 DEBUG [Notifications]: Opening chat for payment request');
          Get.back(); // Close notifications view
          Get.toNamed(
            '/ChatDetailView',
            arguments: {
              'chatId': notification.chatId,
              'otherUserId': notification.data?['payeeId'] ?? '',
              'otherUserName': notification.data?['payeeName'] ?? 'User',
            },
          );
        }
        break;

      case 'payment_declined':
        // Navigate to chat to continue negotiating
        if (notification.chatId != null) {
          print('💬 DEBUG [Notifications]: Opening chat after payment declined');
          Get.back(); // Close notifications view
          Get.toNamed(
            '/ChatDetailView',
            arguments: {
              'chatId': notification.chatId,
              'otherUserId': notification.data?['otherUserId'] ?? '',
              'otherUserName': notification.data?['otherUserName'] ?? 'User',
            },
          );
        }
        break;

      case 'trade_completed':
        if (notification.tradeId != null) {
          // Navigate to trade history or product detail
          Get.snackbar(
            'Trade Details',
            'Trade completed successfully! ID: ${notification.tradeId}',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        break;

      case 'chat_ended':
        Get.snackbar(
          'Chat Ended',
          'This conversation has been closed',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;

      case 'payment_received':
        Get.snackbar(
          'Payment Received',
          'You received a payment!',
          snackPosition: SnackPosition.BOTTOM,
        );
        break;

      default:
        print('⚠️ DEBUG [Notifications]: Unknown notification type: ${notification.type}');
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${dateTime.month}/${dateTime.day}/${dateTime.year.toString().substring(2)}';
  }
}
