import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/bill_history_model.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:undhiyuapp/src/widgets/animations/fade_in_slide.dart';

import 'package:undhiyuapp/src/services/api_service.dart';

class BillHistoryScreen extends StatefulWidget {
  final List<BillRecord> billHistory;
  final Future<void> Function()? onRefresh;
  final Function(BillRecord)? onEditBill;

  const BillHistoryScreen({
    super.key,
    required this.billHistory,
    this.onRefresh,
    this.onEditBill,
  });

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  late List<BillRecord> _displayBills;
  String _searchQuery = '';

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

  List<BillRecord> get _filteredBills {
    if (_searchQuery.isEmpty) return _displayBills;
    return _displayBills.where((bill) {
      final idMatch = bill.id.toLowerCase().contains(_searchQuery.toLowerCase());
      final methodMatch = bill.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());
      final itemMatch = bill.items.any((item) => item.itemName.toLowerCase().contains(_searchQuery.toLowerCase()));
      return idMatch || methodMatch || itemMatch;
    }).toList();
  }

  double get _totalRevenue {
    return _displayBills.fold(0.0, (sum, bill) => sum + bill.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBills;

    return Column(
      children: [
        // Header Banner with Metrics
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Track and manage past sales',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '₹${_totalRevenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Input
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Order ID, Item, or Payment Method...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.primary),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ],
          ),
        ),

        // Bills List
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            color: AppColors.primary,
            child: filtered.isEmpty
                ? Stack(
                    children: [
                      const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(height: 300),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.history_toggle_off_rounded,
                              size: 56,
                              color: AppColors.textTertiary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No bills recorded yet',
                              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bill = filtered[filtered.length - 1 - index]; // Reverse chronological
                      return FadeInSlide(
                        delay: (index % 10) * 0.05,
                        child: _buildBillCard(bill),
                      );
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
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ExpansionTile(
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(bill.timestamp),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${item.quantityInGrams.toStringAsFixed(0)}g @ ₹${item.pricePerGram.toStringAsFixed(2)}/g',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: AppColors.textSecondary)),
                    Text('₹${bill.subtotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
                if (bill.discount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:', style: TextStyle(color: AppColors.textSecondary)),
                      Text('-₹${bill.discount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.error)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bill.paymentMethod == 'upi'
                            ? const Color(0xFF5C6BC0).withOpacity(0.15)
                            : bill.paymentMethod == 'card'
                              ? const Color(0xFF7E57C2).withOpacity(0.15)
                              : AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: bill.paymentMethod == 'upi'
                              ? const Color(0xFF5C6BC0).withOpacity(0.4)
                              : bill.paymentMethod == 'card'
                                ? const Color(0xFF7E57C2).withOpacity(0.4)
                                : AppColors.success.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        bill.paymentMethod.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: bill.paymentMethod == 'upi'
                              ? const Color(0xFF7986CB)
                              : bill.paymentMethod == 'card'
                                ? const Color(0xFF9575CD)
                                : AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                if (bill.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Notes:', style: TextStyle(color: AppColors.textSecondary)),
                      Flexible(
                        child: Text(bill.notes, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editBill(bill),
                          icon: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                          label: const Text('Edit / Clone', style: TextStyle(color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteBill(bill.id),
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                          label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editBill(BillRecord bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit / Clone Bill'),
        content: const Text(
          'This will copy all items from this bill to your current Cart.\n\n'
          'Your existing cart items (if any) will be cleared.\n'
          'The original bill will remain until you delete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Load to Cart'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onEditBill?.call(bill);
    }
  }

  Future<void> _deleteBill(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('Are you sure you want to permanently delete this bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await ApiService().deleteBill(id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bill deleted successfully')),
            );
            // Refresh the list
            widget.onRefresh?.call();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting bill: $e')),
          );
        }
      }
    }
  }
}
