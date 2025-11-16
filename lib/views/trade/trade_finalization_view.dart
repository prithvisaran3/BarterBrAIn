import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants.dart';
import '../../models/trade_model.dart';
import '../../services/trade_service.dart';
import '../../services/nessie_api_service.dart';
import '../../services/chat_service.dart';

class TradeFinalizationView extends StatefulWidget {
  final TradeModel trade;

  const TradeFinalizationView({super.key, required this.trade});

  @override
  State<TradeFinalizationView> createState() => _TradeFinalizationViewState();
}

class _TradeFinalizationViewState extends State<TradeFinalizationView> {
  final _authController = Get.find<AuthController>();
  final _tradeService = Get.find<TradeService>();
  final _nessieService = Get.find<NessieAPIService>();
  final _chatService = Get.find<ChatService>();

  final _paymentController = TextEditingController();

  bool _isLoading = false;
  String _selectedPaymentType = 'direct'; // 'direct', 'now', 'at_exchange'

  @override
  void initState() {
    super.initState();
    // Pre-fill with calculated amount if needed
    if (widget.trade.paymentAmount != null) {
      _paymentController.text = widget.trade.paymentAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  bool _needsPayment() {
    return widget.trade.priceDifference > 10;
  }

  bool _currentUserNeedsToPay() {
    if (!_needsPayment()) return false;
    final currentUserId = _authController.firebaseUser.value!.uid;
    return widget.trade.payingUserId == currentUserId;
  }

  Future<void> _completeTrade() async {
    setState(() => _isLoading = true);

    try {
      String? nessieTransferId;

      // If payment needed and "Pay Now" selected
      if (_needsPayment() && _selectedPaymentType == 'now') {
        final paymentAmount = double.tryParse(_paymentController.text.trim());

        if (paymentAmount == null || paymentAmount <= 0) {
          Get.snackbar(
            'Invalid Amount',
            'Please enter a valid payment amount',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppConstants.errorColor.withOpacity(0.9),
            colorText: Colors.white,
          );
          setState(() => _isLoading = false);
          return;
        }

        // Make payment via Nessie API
        print('💰 DEBUG: Processing payment: \$$paymentAmount');

        final payerUserId = widget.trade.payingUserId!;
        final payeeUserId = payerUserId == widget.trade.initiatorUserId
            ? widget.trade.recipientUserId
            : widget.trade.initiatorUserId;

        final paymentResult = await _nessieService.makePayment(
          payerUserId: payerUserId,
          payeeUserId: payeeUserId,
          amount: paymentAmount,
          description: 'BarterBrAIn Trade Payment - Trade ${widget.trade.id}',
        );

        if (paymentResult['success'] != true) {
          throw Exception(paymentResult['error'] ?? 'Payment failed');
        }

        nessieTransferId = paymentResult['transferId'] as String?;
        print('✅ DEBUG: Payment successful: $nessieTransferId');
      }

      // Complete the trade
      await _tradeService.completeTrade(
        tradeId: widget.trade.id,
        paymentType: _selectedPaymentType,
        isPaid: _selectedPaymentType == 'now',
        nessieTransferId: nessieTransferId,
      );

      // Send system message to chat
      await _chatService.sendSystemMessage(
        chatId: widget.trade.chatId,
        systemMessage: 'Trade completed successfully! 🎉',
      );

      // Close chat
      await _chatService.endChat(
        chatId: widget.trade.chatId,
        endedBy: _authController.firebaseUser.value!.uid,
        reason: 'trade_completed',
        otherUserId: widget.trade.initiatorUserId == _authController.firebaseUser.value!.uid
            ? widget.trade.recipientUserId
            : widget.trade.initiatorUserId,
        currentUserName: _authController.userModel.value!.displayName ?? 'Unknown',
      );

      print('✅ DEBUG: Trade completed successfully!');

      // Show success
      Get.back(); // Close finalization
      Get.back(); // Close chat
      Get.back(); // Close product detail

      Get.snackbar(
        'Trade Completed! 🎉',
        'Your trade has been finalized successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppConstants.successColor.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('❌ DEBUG: Error completing trade: $e');
      Get.snackbar(
        'Error',
        'Failed to complete trade: ${e.toString()}',
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
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: const Text('Finalize Trade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.1),
                    Colors.green.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 12),
                  Text(
                    'Both Confirmed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.tertiaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re ready to complete this trade',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Trade Summary
            _buildTradeSummary(),

            const SizedBox(height: 24),

            // Payment Section
            if (_needsPayment()) ...[
              _buildPaymentSection(),
              const SizedBox(height: 24),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No payment needed!\nPrice difference is within \$10',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Complete Button
            CNButton(
              label: _isLoading ? 'Completing Trade...' : 'Complete Trade',
              onPressed: _isLoading ? null : _completeTrade,
            ),

            const SizedBox(height: 16),

            // Info
            Text(
              'Once completed, the trade cannot be undone. Make sure both parties agree!',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.systemGray6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trade Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.tertiaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Your Products',
            '${_isInitiator() ? widget.trade.initiatorProductIds.length : widget.trade.recipientProductIds.length} items',
            '\$${_isInitiator() ? widget.trade.initiatorTotalValue.toStringAsFixed(2) : widget.trade.recipientTotalValue.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Their Products',
            '${_isInitiator() ? widget.trade.recipientProductIds.length : widget.trade.initiatorProductIds.length} items',
            '\$${_isInitiator() ? widget.trade.recipientTotalValue.toStringAsFixed(2) : widget.trade.initiatorTotalValue.toStringAsFixed(2)}',
          ),
          const Divider(height: 24),
          _buildSummaryRow(
            'Price Difference',
            '',
            '\$${widget.trade.priceDifference.toStringAsFixed(2)}',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String count, String amount, {bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                  color: AppConstants.tertiaryColor,
                ),
              ),
              if (count.isNotEmpty)
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: highlight ? AppConstants.primaryColor : AppConstants.tertiaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Required',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.tertiaryColor,
          ),
        ),
        const SizedBox(height: 12),

        // Who pays
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _currentUserNeedsToPay()
                ? '💰 You need to pay \$${widget.trade.paymentAmount!.toStringAsFixed(2)}'
                : '💰 They need to pay \$${widget.trade.paymentAmount!.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
        ),

        if (_currentUserNeedsToPay()) ...[
          const SizedBox(height: 16),

          // Payment Amount Input
          TextField(
            controller: _paymentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Payment Amount',
              prefixText: '\$ ',
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Enter the amount you agreed to pay',
            ),
          ),

          const SizedBox(height: 16),

          // Payment Options
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.tertiaryColor,
            ),
          ),
          const SizedBox(height: 12),

          _buildPaymentOption(
            'now',
            'Pay Now',
            'Complete payment via Capital One',
            Icons.payment,
          ),
          const SizedBox(height: 8),
          _buildPaymentOption(
            'at_exchange',
            'Pay at Exchange',
            'Pay when you meet in person',
            Icons.handshake,
          ),
        ] else ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.systemGray6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Waiting for payment confirmation from the other user',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOption(String value, String title, String description, IconData icon) {
    final isSelected = _selectedPaymentType == value;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentType = value);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : AppConstants.systemGray6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppConstants.primaryColor : AppConstants.systemGray,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppConstants.primaryColor : AppConstants.tertiaryColor,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppConstants.primaryColor : AppConstants.systemGray2,
            ),
          ],
        ),
      ),
    );
  }

  bool _isInitiator() {
    return widget.trade.initiatorUserId == _authController.firebaseUser.value!.uid;
  }
}

