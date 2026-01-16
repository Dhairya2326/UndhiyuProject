import 'package:flutter/material.dart';

class PaymentButtons extends StatelessWidget {
  final double total;
  final VoidCallback onCashPressed;
  final VoidCallback onUPIPressed;

  const PaymentButtons({
    super.key,
    required this.total,
    required this.onCashPressed,
    required this.onUPIPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: onCashPressed,
          icon: const Icon(Icons.money),
          label: const Text('Cash'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: total > 0 ? onUPIPressed : null,
          icon: const Icon(Icons.qr_code),
          label: const Text('UPI'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}
