import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';
import 'package:undhiyuapp/src/services/api_service.dart';

class BillSummaryWidget extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(double, String, {double discount, String notes}) onPayment;

  const BillSummaryWidget({
    super.key,
    required this.cartItems,
    required this.onPayment,
  });

  @override
  State<BillSummaryWidget> createState() => _BillSummaryWidgetState();
}

class _BillSummaryWidgetState extends State<BillSummaryWidget> {
  final ApiService _apiService = ApiService();
  double discountPercent = 0;
  String notes = '';
  
  String? _upiName;
  String? _qrCodeUrl;

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final config = await _apiService.fetchPaymentConfig();
      if (mounted && config.isNotEmpty) {
        setState(() {
          _upiName = config['upiName'];
          _qrCodeUrl = config['qrCodeUrl'];
        });
      }
    } catch (e) {
      print('Error loading payment config: $e');
    }
  }

  double get subtotal => widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => (subtotal * discountPercent) / 100;
  double get total => subtotal - discountAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, -6),
            blurRadius: 16,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Input Fields
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Discount %',
                      prefixIcon: const Icon(Icons.percent, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        discountPercent = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Order Notes',
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onChanged: (value) => notes = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calculation Rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15)),
              ],
            ),
            if (discountPercent > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount ($discountPercent%)', style: const TextStyle(color: AppColors.error, fontSize: 14)),
                  Text('-₹${discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: AppColors.divider),
            ),
            
            // Total highlight container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total to Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Payment Methods
            Row(
              children: [
                _buildPaymentButton(
                  icon: Icons.payments_outlined,
                  label: 'CASH',
                  color: AppColors.success,
                  onTap: () => _processPayment('cash'),
                ),
                const SizedBox(width: 10),
                _buildPaymentButton(
                  icon: Icons.qr_code_scanner,
                  label: 'UPI',
                  color: const Color(0xFF5C6BC0),
                  onTap: () => _processPayment('upi'),
                ),
                const SizedBox(width: 10),
                _buildPaymentButton(
                  icon: Icons.credit_card_outlined,
                  label: 'CARD',
                  color: const Color(0xFF7E57C2),
                  onTap: () => _processPayment('card'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool disabled = widget.cartItems.isEmpty;
    return Expanded(
      child: Material(
        color: disabled ? AppColors.surfaceVariant : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: color.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: disabled ? AppColors.border : color.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: disabled ? AppColors.textTertiary : color, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: disabled ? AppColors.textTertiary : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _processPayment(String method) {
    if (method == 'upi') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Center(
            child: Text('Scan QR to Pay', style: TextStyle(color: AppColors.textPrimary)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_upiName != null && _upiName!.isNotEmpty) ...[
                Text(
                  _upiName!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _qrCodeUrl != null && _qrCodeUrl!.isNotEmpty
                  ? Image.network(
                      ApiService.formatImageUrl(_qrCodeUrl!),
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildFallbackQR();
                      },
                    )
                  : _buildFallbackQR(),
              ),
              const SizedBox(height: 24),
              const Text('Total Amount', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPayment(total, method, discount: discountAmount, notes: notes);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Payment Received'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.all(20),
        ),
      );
    } else {
      widget.onPayment(total, method, discount: discountAmount, notes: notes);
    }
  }

  Widget _buildFallbackQR() {
    return Image.asset(
      'assets/images/qr_code.jpeg',
      width: 200,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
         return const Icon(Icons.qr_code_2, size: 200, color: Colors.black);
      },
    );
  }
}
