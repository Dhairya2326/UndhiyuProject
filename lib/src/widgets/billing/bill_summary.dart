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
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Discount input
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Discount (%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.local_offer),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      discountPercent = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                  maxLines: 1,
                  onChanged: (value) => notes = value,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bill summary
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', subtotal),
                if (discountPercent > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Discount ($discountPercent%)',
                    -discountAmount,
                    isDiscount: true,
                  ),
                ],
                const Divider(height: 16),
                _buildSummaryRow(
                  'Total Amount',
                  total,
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.cartItems.isEmpty
                      ? null
                      : () {
                          widget.onPayment(total, 'cash', discount: discountAmount, notes: notes);
                          _showPaymentConfirmation('Cash Payment');
                        },
                  icon: const Icon(Icons.money),
                  label: const Text('Cash Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.cartItems.isEmpty
                      ? null
                      : () {
                          widget.onPayment(total, 'upi', discount: discountAmount, notes: notes);
                          _showPaymentConfirmation('UPI Payment');
                        },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('UPI Payment'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount ? Colors.red : Colors.black,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : (isDiscount ? Colors.red : Colors.black),
          ),
        ),
      ],
    );
  }

  void _showPaymentConfirmation(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method confirmed - ₹${total.toStringAsFixed(0)}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
