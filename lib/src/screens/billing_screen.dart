import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  double total = 0;

  @override
  void dispose() {
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  void calculateBill() {
    final price = double.tryParse(priceController.text) ?? 0;
    final quantity = double.tryParse(quantityController.text) ?? 0;

    setState(() {
      total = price * quantity;
    });
  }

  Future<void> payWithUPI() async {
    final upiUrl =
        "upi://pay?pa=yourupi@bank&pn=Undhiyu%20Shop&am=${total.toStringAsFixed(2)}&cu=INR";

    final uri = Uri.parse(upiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("UPI app not found")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🥘 Undhiyu Billing"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price per plate / kg (₹)",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => calculateBill(),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantity",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => calculateBill(),
            ),

            const SizedBox(height: 24),

            Text(
              "Total Bill: ₹${total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cash payment received")),
                    );
                  },
                  icon: const Icon(Icons.money),
                  label: const Text("Cash"),
                ),

                ElevatedButton.icon(
                  onPressed: total > 0 ? payWithUPI : null,
                  icon: const Icon(Icons.qr_code),
                  label: const Text("UPI"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
