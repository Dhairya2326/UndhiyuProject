import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

class PricingCalculator extends StatefulWidget {
  final Function(double) onCalculated;

  const PricingCalculator({
    super.key,
    required this.onCalculated,
  });

  @override
  State<PricingCalculator> createState() => _PricingCalculatorState();
}

class _PricingCalculatorState extends State<PricingCalculator> {
  final _basePriceController = TextEditingController();
  final _baseUnitController = TextEditingController(text: '1');
  final _quantityController = TextEditingController();
  double _calculatedPrice = 0;

  @override
  void dispose() {
    _basePriceController.dispose();
    _baseUnitController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    final basePrice = double.tryParse(_basePriceController.text) ?? 0;
    final baseUnit = double.tryParse(_baseUnitController.text) ?? 1;
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    setState(() {
      _calculatedPrice = (quantity / baseUnit) * basePrice;
    });

    widget.onCalculated(_calculatedPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calculate, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Pricing Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Base Price (₹)',
                      border: OutlineInputBorder(),
                      hintText: '100',
                    ),
                    onChanged: (_) => _calculatePrice(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _baseUnitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Per (kg/unit)',
                      border: OutlineInputBorder(),
                      hintText: '1',
                    ),
                    onChanged: (_) => _calculatePrice(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity (kg/unit)',
                border: OutlineInputBorder(),
                hintText: '2.5',
              ),
              onChanged: (_) => _calculatePrice(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calculated Price:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${_calculatedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
