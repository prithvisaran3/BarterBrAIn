import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class TransactionHistoryView extends StatefulWidget {
  const TransactionHistoryView({super.key});

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  final _authController = Get.find<AuthController>();
  final _transactionService = Get.find<TransactionService>();

  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = _authController.firebaseUser.value!.uid;
    final stats = await _transactionService.getUserTransactionStats(userId);
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authController.firebaseUser.value!.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
        title: const Text('Transaction History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats Card
          if (_stats != null) _buildStatsCard(),

          // Transactions List
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getUserTransactions(userId),
              builder: (context, snapshot) {
                print('🔍 DEBUG [TransactionHistory]: ConnectionState: ${snapshot.connectionState}');
                print('🔍 DEBUG [TransactionHistory]: HasData: ${snapshot.hasData}');
                print('🔍 DEBUG [TransactionHistory]: HasError: ${snapshot.hasError}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppConstants.primaryColor),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  print('❌ ERROR [TransactionHistory]: ${snapshot.error}');
                  print('❌ ERROR [TransactionHistory]: Stack trace: ${snapshot.stackTrace}');
                  
                  // If we have data despite the error, show the data
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    print('✅ DEBUG [TransactionHistory]: Has data despite error, showing ${snapshot.data!.length} transactions');
                    final transactions = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(transactions[index], userId);
                      },
                    );
                  }
                  
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppConstants.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading transactions',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data ?? [];

                if (transactions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionCard(transactions[index], userId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalPaid = _stats!['totalPaid'] as double;
    final totalReceived = _stats!['totalReceived'] as double;
    final netBalance = _stats!['netBalance'] as double;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Transaction Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.arrow_upward,
                  label: 'Paid',
                  value: '\$${totalPaid.toStringAsFixed(2)}',
                  color: Colors.red.shade300,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.arrow_downward,
                  label: 'Received',
                  value: '\$${totalReceived.toStringAsFixed(2)}',
                  color: Colors.green.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Net Balance: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '\$${netBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: netBalance >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction, String currentUserId) {
    final isPayer = transaction.payerUserId == currentUserId;
    final otherUserName = isPayer ? transaction.payeeName : transaction.payerName;
    final otherUserPhoto = isPayer ? transaction.payeePhoto : transaction.payerPhoto;
    final isOutgoing = isPayer;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppConstants.systemGray3.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          onTap: () => _showTransactionDetails(transaction, isPayer),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: otherUserPhoto != null
                      ? CachedNetworkImageProvider(otherUserPhoto)
                      : null,
                  child: otherUserPhoto == null
                      ? Text((otherUserName ?? '?')[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),

                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUserName ?? 'Unknown User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.tertiaryColor,
                              ),
                            ),
                          ),
                          Text(
                            '${isOutgoing ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isOutgoing ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.paymentMethodDisplay,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getStatusIcon(transaction.status),
                            size: 14,
                            color: _getStatusColor(transaction.status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            transaction.displayStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(transaction.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM d, y').format(transaction.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondary,
                            ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green.shade600;
      case 'processing':
        return Colors.blue.shade600;
      case 'pending':
        return Colors.orange.shade600;
      case 'failed':
        return Colors.red.shade600;
      default:
        return AppConstants.textSecondary;
    }
  }

  void _showTransactionDetails(TransactionModel transaction, bool isPayer) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppConstants.radiusXl),
            topRight: Radius.circular(AppConstants.radiusXl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.systemGray4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(transaction.status),
                    size: 48,
                    color: _getStatusColor(transaction.status),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${isPayer ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: isPayer ? Colors.red.shade600 : Colors.green.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  transaction.displayStatus,
                  style: TextStyle(
                    fontSize: 16,
                    color: _getStatusColor(transaction.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildDetailRow('From', transaction.payerName ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow('To', transaction.payeeName ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow('Payment Method', transaction.paymentMethodDisplay),
              const SizedBox(height: 12),
              _buildDetailRow('Date', DateFormat('MMMM d, y h:mm a').format(transaction.createdAt)),
              if (transaction.completedAt != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Completed',
                  DateFormat('MMMM d, y h:mm a').format(transaction.completedAt!),
                ),
              ],
              if (transaction.nessieTransferId != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Transaction ID', transaction.nessieTransferId!),
              ],
              if (transaction.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.systemGray6,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: Text(
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.tertiaryColor,
                    ),
                  ),
                ),
              ],
              if (transaction.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.tertiaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.systemGray6,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: AppConstants.systemGray2,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Transactions Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppConstants.tertiaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your transaction history will appear here when you complete trades with payments.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

