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

class _BillingScreenState extends State<BillingScreen> with SingleTickerProviderStateMixin {
  final BillingService _billingService = BillingService();
  final ApiService _apiService = ApiService();
  final List<CartItem> _cartItems = [];
  final List<BillRecord> _billHistory = [];
  List<MenuItem> _menuItems = [];
  bool _isLoadingMenu = true;
  String? _menuError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMenuItems();
    // Listen to tab changes to fetch data when needed
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _refreshCurrentTab();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentTab() async {
    if (_tabController.index == 0) {
      await _loadMenuItems();
    } else if (_tabController.index == 1) {
      // Refreshing menu items updates stock availability for cart items too
      await _loadMenuItems();
    } else if (_tabController.index == 2) {
      await _loadBillHistory();
    }
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoadingMenu = true;
      _menuError = null;
    });

    try {
      final items = await _apiService.fetchMenuItems();
      if (mounted) {
        setState(() {
          _menuItems = items;
          _isLoadingMenu = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _menuError = e.toString();
          _isLoadingMenu = false;
        });
      }
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

  Future<void> _loadBillHistory() async {
    try {
      final history = await _apiService.fetchAllBills();
      if (mounted) {
        setState(() {
          _billHistory.clear();
          _billHistory.addAll(history);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load history: $e')));
      }
    }
  }

  Future<void> _handlePayment(
    double amount,
    String method, {
    double discount = 0,
    String notes = '',
  }) async {
    try {
      // Call API to create bill
      await _apiService.createBill(
        cartItems: _cartItems,
        discount: discount,
        paymentMethod: method,
        notes: notes,
      );

      _billingService.recordTransaction(amount: amount, method: method);

      if (method == 'upi') {
        _billingService.payWithUPI(amount);
      }

      // Clear cart
      setState(() {
        _cartItems.clear();
      });

      // Provide feedback and navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Order Placed Successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Switch to history tab to show the new order
        _tabController.animateTo(2);
      }

      // Refresh history
      _loadBillHistory();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Error', style: TextStyle(color: AppColors.error)),
            content: Text('Failed to record bill: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleEditBill(BillRecord bill) {
    setState(() {
      _cartItems.clear();
      for (final billItem in bill.items) {
        // Find the matching menu item to ensure we have the full object
        // If not found (e.g. deleted), we might have issues. 
        // For now, reconstruct a partial MenuItem or try to find it.
        
        final menuItem = _menuItems.firstWhere(
          (m) => m.name == billItem.itemName, // Match by Name if ID matches or fallback
          orElse: () => MenuItem(
            id: 'unknown',
            name: billItem.itemName,
            category: 'Unknown',
            price: billItem.pricePerGram,
            description: '',
            icon: billItem.icon,
            available: true,
          ),
        );
        
        // If we found it by name/ID, use it. Ideally we should match by ID if BillItem had it.
        // BillItem in backend has `itemName`, `icon` etc. but originally created from MenuItem.
        // Let's verify BillRecord model.
        
        _cartItems.add(CartItem(
          menuItem: menuItem,
          quantityInGrams: billItem.quantityInGrams,
        ));
      }
    });

    // Switch to Cart Tab
    _tabController.animateTo(1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill loaded into Cart!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Shivam Caterers',
        ),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
               _refreshCurrentTab();
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Refreshing data...'), duration: Duration(milliseconds: 500)),
               );
            },
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 4,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            const Tab(text: 'Menu', icon: Icon(Icons.restaurant_menu)),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.shopping_cart),
                   const SizedBox(width: 8),
                   const Text('Cart'),
                   if (_cartItems.isNotEmpty) ...[
                     const SizedBox(width: 8),
                     Badge(
                       label: Text('${_cartItems.length}'),
                       backgroundColor: AppColors.primary,
                       textColor: Colors.black,
                     ),
                   ],
                ],
              ),
            ),
            const Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(),
          _buildBillTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildBillTab() {
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Browse Menu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Bill items
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BillItemsWidget(
                  cartItems: _cartItems,
                  onRemoveItem: _removeFromCart,
                  onQuantityChanged: _updateQuantity,
                ),
              ),
            ),
          ),
        ),

        // Bill summary
        BillSummaryWidget(cartItems: _cartItems, onPayment: _handlePayment),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      color: AppColors.background,
      child: BillHistoryScreen(
        billHistory: _billHistory,
        onRefresh: _loadBillHistory, // Pass Refresh Callback
        onEditBill: _handleEditBill,
      ),
    );
  }

  Widget _buildFormTab() {
    if (_isLoadingMenu) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            SizedBox(height: 16),
            Text('Loading yummy items...'),
          ],
        ),
      );
    }

    if (_menuError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading menu: $_menuError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMenuItems,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return BillingFormScreen(
      menuItems: _menuItems,
      onRefresh: _loadMenuItems, // Pass Refresh Callback
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cartItem.menuItem.name} added to cart'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
             action: SnackBarAction(
              label: 'VIEW CART',
              textColor: AppColors.primaryLight,
              onPressed: () => _tabController.animateTo(1),
            ),
          ),
        );
      },
      cartItems: _cartItems,
    );
  }
}
