import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/trade_model.dart';
import '../../services/trade_service.dart';

class TradeHistoryView extends StatelessWidget {
  const TradeHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final tradeService = Get.find<TradeService>();
    final currentUserId = authController.firebaseUser.value?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Trade History'),
      ),
      body: StreamBuilder<List<TradeModel>>(
        stream: tradeService.getUserTrades(currentUserId),
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
                    'Error loading trades',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final trades = snapshot.data!;
          final completedTrades = trades.where((t) => t.isCompleted).toList();
          final activeTrades = trades.where((t) => !t.isCompleted && !t.isCancelled).toList();
          final cancelledTrades = trades.where((t) => t.isCancelled).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active Trades
              if (activeTrades.isNotEmpty) ...[
                _buildSectionHeader('Active Trades', activeTrades.length),
                const SizedBox(height: 12),
                ...activeTrades.map((trade) => _buildTradeCard(trade, currentUserId)),
                const SizedBox(height: 24),
              ],

              // Completed Trades
              if (completedTrades.isNotEmpty) ...[
                _buildSectionHeader('Completed', completedTrades.length),
                const SizedBox(height: 12),
                ...completedTrades.map((trade) => _buildTradeCard(trade, currentUserId, isCompleted: true)),
                const SizedBox(height: 24),
              ],

              // Cancelled Trades
              if (cancelledTrades.isNotEmpty) ...[
                _buildSectionHeader('Cancelled', cancelledTrades.length),
                const SizedBox(height: 12),
                ...cancelledTrades.map((trade) => _buildTradeCard(trade, currentUserId, isCancelled: true)),
              ],
            ],
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
              Icons.swap_horiz,
              size: 60,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Trades Yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your trade history will appear here',
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

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTradeCard(TradeModel trade, String currentUserId, {bool isCompleted = false, bool isCancelled = false}) {
    final isInitiator = trade.initiatorUserId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : isCancelled
                  ? AppConstants.errorColor.withOpacity(0.3)
                  : AppConstants.primaryColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isCancelled
                        ? Icons.cancel
                        : Icons.hourglass_empty,
                color: isCompleted
                    ? Colors.green
                    : isCancelled
                        ? AppConstants.errorColor
                        : AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCompleted
                      ? 'Completed Trade'
                      : isCancelled
                          ? 'Cancelled Trade'
                          : 'Active Trade',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.tertiaryColor,
                  ),
                ),
              ),
              if (isCompleted && trade.completedAt != null)
                Text(
                  _formatDate(trade.completedAt!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Trade Details
          _buildTradeRow(
            'Your Products',
            '${isInitiator ? trade.initiatorProductIds.length : trade.recipientProductIds.length} items',
            '\$${isInitiator ? trade.initiatorTotalValue.toStringAsFixed(2) : trade.recipientTotalValue.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _buildTradeRow(
            'Their Products',
            '${isInitiator ? trade.recipientProductIds.length : trade.initiatorProductIds.length} items',
            '\$${isInitiator ? trade.recipientTotalValue.toStringAsFixed(2) : trade.initiatorTotalValue.toStringAsFixed(2)}',
          ),

          // Price Difference
          if (trade.priceDifference > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Price Difference',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.tertiaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${trade.priceDifference.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            if (trade.paymentAmount != null && trade.paymentAmount! > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: AppConstants.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trade.isPaid
                            ? 'Payment completed: \$${trade.paymentAmount!.toStringAsFixed(2)}'
                            : 'Payment pending: \$${trade.paymentAmount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          // Trade ID
          const SizedBox(height: 16),
          Text(
            'Trade ID: ${trade.id.substring(0, 8)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.systemGray2,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeRow(String label, String count, String amount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.tertiaryColor,
                ),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}

