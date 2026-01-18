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
    // ... existing build method ...
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
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
                      prefixIcon: const Icon(Icons.percent, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      prefixIcon: const Icon(Icons.note, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (value) => notes = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Calculation Rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (discountPercent > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Discount ($discountPercent%)', style: const TextStyle(color: AppColors.error)),
                  Text('-₹${discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total to Pay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 24),

            // Payment Methods
            Row(
              children: [
                _buildPaymentButton(
                  icon: Icons.money,
                  label: 'CASH',
                  color: Colors.green,
                  onTap: () => _processPayment('cash'),
                ),
                const SizedBox(width: 12),
                _buildPaymentButton(
                  icon: Icons.qr_code_scanner,
                  label: 'UPI',
                  color: Colors.blue,
                  onTap: () => _processPayment('upi'),
                ),
                 const SizedBox(width: 12),
                _buildPaymentButton(
                  icon: Icons.credit_card,
                  label: 'CARD',
                  color: Colors.deepPurple,
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
    return Expanded(
      child: Material(
        color: widget.cartItems.isEmpty ? Colors.grey[300] : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.cartItems.isEmpty ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: widget.cartItems.isEmpty ? Colors.grey : color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: widget.cartItems.isEmpty ? Colors.grey : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(child: Text('Scan QR to Pay')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_upiName != null && _upiName!.isNotEmpty) ...[
                Text(
                  _upiName!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _qrCodeUrl != null && _qrCodeUrl!.isNotEmpty
                  ? Image.network(
                      ApiService.baseUrl.replaceAll('/api/v1', '') + _qrCodeUrl!,
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
              const Text('Total Amount', style: TextStyle(color: Colors.grey)),
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
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPayment(total, method, discount: discountAmount, notes: notes);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
