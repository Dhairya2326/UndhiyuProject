import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/models/bill_history_model.dart';
import 'package:undhiyuapp/src/services/billing_service.dart';
import 'package:undhiyuapp/src/services/api_service.dart';
import 'package:undhiyuapp/src/screens/billing/billing_form_screen.dart';
import 'package:undhiyuapp/src/screens/billing/bill_history_screen.dart';
import 'package:undhiyuapp/src/widgets/billing/bill_items.dart';
import 'package:undhiyuapp/src/widgets/billing/bill_summary.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final BillingService _billingService = BillingService();
  final ApiService _apiService = ApiService();
  final List<CartItem> _cartItems = [];
  final List<BillRecord> _billHistory = [];
  List<MenuItem> _menuItems = [];
  bool _isLoadingMenu = true;
  String? _menuError;
  int _tabIndex = 0; // 0: Quick Bill, 1: Bill, 2: Bill History

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoadingMenu = true;
      _menuError = null;
    });

    try {
      final items = await _apiService.fetchMenuItems();
      setState(() {
        _menuItems = items;
        _isLoadingMenu = false;
      });
    } catch (e) {
      setState(() {
        _menuError = e.toString();
        _isLoadingMenu = false;
      });
    }
  }



  void _removeFromCart(CartItem cartItem) {
    setState(() {
      _cartItems.remove(cartItem);
    });
  }

  void _updateQuantity(CartItem cartItem) {
    setState(() {
      // Trigger rebuild
    });
  }

  void _handlePayment(double amount, String method, {double discount = 0, String notes = ''}) {
    _billingService.recordTransaction(
      amount: amount,
      method: method,
    );

    // Create bill record
    final billItems = _cartItems.map((cartItem) {
      return BillItem(
        itemName: cartItem.menuItem.name,
        icon: cartItem.menuItem.icon,
        quantityInGrams: cartItem.quantityInGrams,
        pricePerGram: cartItem.menuItem.price,
        totalPrice: cartItem.totalPrice,
      );
    }).toList();

    final subtotal = _cartItems.fold<double>(0, (sum, item) => sum + item.totalPrice);
    
    final billRecord = BillRecord(
      id: 'BILL_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      items: billItems,
      subtotal: subtotal,
      discount: discount,
      totalAmount: amount,
      paymentMethod: method,
      notes: notes,
    );

    _billHistory.add(billRecord);

    if (method == 'upi') {
      _billingService.payWithUPI(amount);
    }

    // Clear cart
    setState(() {
      _cartItems.clear();
      _tabIndex = 1;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Bill recorded.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🥘 Restaurant Billing'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            color: AppColors.primary,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('Quick Bill', 0),
                  _buildTabButton('Bill', 1),
                  _buildTabButton('History', 2),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _tabIndex == 0
                ? _buildFormTab()
                : _tabIndex == 1
                    ? _buildBillTab()
                    : _buildHistoryTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillTab() {
    return Column(
      children: [
        // Bill items
        Expanded(
          child: BillItemsWidget(
            cartItems: _cartItems,
            onRemoveItem: _removeFromCart,
            onQuantityChanged: _updateQuantity,
          ),
        ),

        // Bill summary
        BillSummaryWidget(
          cartItems: _cartItems,
          onPayment: _handlePayment,
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return BillHistoryScreen(billHistory: _billHistory);
  }

  Widget _buildTabButton(String label, int index) {
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _tabIndex == index ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: _tabIndex == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFormTab() {
    if (_isLoadingMenu) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_menuError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading menu: $_menuError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMenuItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return BillingFormScreen(
      menuItems: _menuItems,
      onAddToCart: (cartItem) {
        setState(() {
          bool found = false;
          for (final item in _cartItems) {
            if (item.menuItem.id == cartItem.menuItem.id) {
              item.addGrams(cartItem.quantityInGrams);
              found = true;
              break;
            }
          }
          if (!found) {
            _cartItems.add(cartItem);
          }
        });
      },
      cartItems: _cartItems,
    );
  }
}