import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

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
  double discountPercent = 0;
  String notes = '';

  double get subtotal => widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => (subtotal * discountPercent) / 100;
  double get total => subtotal - discountAmount;

  @override
  Widget build(BuildContext context) {
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
    widget.onPayment(total, method, discount: discountAmount, notes: notes);
  }
}
