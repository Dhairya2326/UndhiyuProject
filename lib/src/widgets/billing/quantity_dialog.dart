import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

class QuantityDialog extends StatefulWidget {
  final String itemName;
  final double pricePerKg;
  final Function(double) onConfirm;

  const QuantityDialog({
    super.key,
    required this.itemName,
    required this.pricePerKg,
    required this.onConfirm,
  });

  @override
  State<QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog> {
  final _gramController = TextEditingController();
  double _calculatedPrice = 0;

  @override
  void dispose() {
    _gramController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    final grams = double.tryParse(_gramController.text) ?? 0;
    setState(() {
      _calculatedPrice = grams * widget.pricePerKg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add ${widget.itemName} to Cart',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Price per gram:', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    '₹${widget.pricePerKg.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gramController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity (grams)',
                hintText: '500',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              onChanged: (_) => _calculatePrice(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Price:'),
                      Text(
                        '₹${_calculatedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(${(_gramController.text.isEmpty ? 0 : double.parse(_gramController.text)) / 1000} kg)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final grams = double.tryParse(_gramController.text) ?? 0;
            if (grams <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid quantity')),
              );
              return;
            }
            widget.onConfirm(grams);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
          ),
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
