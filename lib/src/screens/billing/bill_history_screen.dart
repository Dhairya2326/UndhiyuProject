import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/bill_history_model.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';
import 'package:intl/intl.dart';

class BillHistoryScreen extends StatefulWidget {
  final List<BillRecord> billHistory;
  final Future<void> Function()? onRefresh;

  const BillHistoryScreen({
    super.key,
    required this.billHistory,
    this.onRefresh,
  });

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  late List<BillRecord> _displayBills;

  @override
  void initState() {
    super.initState();
    _displayBills = widget.billHistory;
  }
  
  @override
  void didUpdateWidget(BillHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.billHistory != oldWidget.billHistory) {
      setState(() {
         _displayBills = widget.billHistory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'Bill History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_displayBills.length} bills',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Total Revenue: ₹${_displayBills.fold<double>(0, (sum, bill) => sum + bill.totalAmount).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Bills List
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            child: _displayBills.isEmpty
                ? Stack(
                    children: [
                      ListView(), // Scrollable to allow RefreshIndicator to work even if empty
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.history,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No bills recorded yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _displayBills.length,
                    itemBuilder: (context, index) {
                      final bill = _displayBills[_displayBills.length - 1 - index]; // Reverse order
                      return _buildBillCard(bill);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillCard(BillRecord bill) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${bill.id.substring(bill.id.length - 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(bill.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Text(
              '₹${bill.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...bill.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(item.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.itemName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${item.quantityInGrams.toStringAsFixed(0)}g @ ₹${item.pricePerGram.toStringAsFixed(2)}/g',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('₹${bill.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
                if (bill.discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:'),
                      Text('-₹${bill.discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Chip(
                      label: Text(bill.paymentMethod.toUpperCase()),
                      backgroundColor: bill.paymentMethod == 'upi'
                          ? Colors.blue.shade100
                          : Colors.green.shade100,
                    ),
                  ],
                ),
                if (bill.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notes:'),
                      Text(bill.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
