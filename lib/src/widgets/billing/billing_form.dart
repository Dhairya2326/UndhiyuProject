import 'package:flutter/material.dart';

class BillingForm extends StatefulWidget {
  final Function(double price, double quantity) onChanged;

  const BillingForm({
    super.key,
    required this.onChanged,
  });

  @override
  State<BillingForm> createState() => _BillingFormState();
}

class _BillingFormState extends State<BillingForm> {
  late TextEditingController priceController;
  late TextEditingController quantityController;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController();
    quantityController = TextEditingController();
  }

  @override
  void dispose() {
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void _handleChange() {
    final price = double.tryParse(priceController.text) ?? 0;
    final quantity = double.tryParse(quantityController.text) ?? 0;
    widget.onChanged(price, quantity);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price per plate / kg (₹)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.currency_rupee),
          ),
          onChanged: (_) => _handleChange(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.shopping_cart),
          ),
          onChanged: (_) => _handleChange(),
        ),
      ],
    );
  }
}
