import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';
import 'package:undhiyuapp/src/services/api_service.dart';
import 'package:undhiyuapp/src/widgets/animations/fade_in_slide.dart';
import 'package:undhiyuapp/src/widgets/animations/scale_button.dart';

class BillingFormScreen extends StatefulWidget {
  final List<MenuItem> menuItems;
  final Function(CartItem) onAddToCart;
  final List<CartItem> cartItems;
  final Future<void> Function()? onRefresh;

  const BillingFormScreen({
    super.key,
    required this.menuItems,
    required this.onAddToCart,
    required this.cartItems,
    this.onRefresh,
  });

  @override
  State<BillingFormScreen> createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends State<BillingFormScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<String> get _categories {
    final cats = widget.menuItems.map((e) => e.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<MenuItem> get _filteredItems {
    return widget.menuItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _openQuantityDialog(MenuItem item) {
    final quantityController = TextEditingController(text: '250'); // Default 250g
    double price = 0;
    String? stockError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final qty = double.tryParse(quantityController.text) ?? 0;
            price = qty * item.price;

            // Stock validation
            final bool exceedsStock = item.stockQuantity > 0 && qty > item.stockQuantity;
            final bool invalidQty = qty <= 0 && quantityController.text.isNotEmpty;
            
            if (exceedsStock) {
              stockError = 'Exceeds available stock (${(item.stockQuantity / 1000).toStringAsFixed(1)} kg)';
            } else if (invalidQty) {
              stockError = 'Quantity must be greater than 0';
            } else {
              stockError = null;
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Row(
                children: [
                   Text(item.icon, style: const TextStyle(fontSize: 24)),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       item.name,
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(color: AppColors.textPrimary),
                     ),
                   ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stock indicator
                  if (item.stockQuantity > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: item.stockQuantity < item.lowStockThreshold
                            ? AppColors.warning.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: item.stockQuantity < item.lowStockThreshold
                              ? AppColors.warning.withOpacity(0.3)
                              : AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.stockQuantity < item.lowStockThreshold
                                ? Icons.warning_amber_rounded
                                : Icons.inventory_2_outlined,
                            size: 16,
                            color: item.stockQuantity < item.lowStockThreshold
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available: ${(item.stockQuantity / 1000).toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: item.stockQuantity < item.lowStockThreshold
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity (grams)',
                      suffixText: 'g',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      errorText: stockError,
                      errorStyle: const TextStyle(color: AppColors.error),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick quantity buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [100, 250, 500, 1000].map((g) {
                      return GestureDetector(
                        onTap: () {
                          quantityController.text = g.toString();
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: quantityController.text == g.toString()
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: quantityController.text == g.toString()
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            g >= 1000 ? '${g ~/ 1000}kg' : '${g}g',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: quantityController.text == g.toString()
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price per gram: ₹${item.price.toStringAsFixed(3)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Price:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: (stockError != null || qty <= 0)
                      ? null
                      : () {
                          widget.onAddToCart(CartItem(
                            menuItem: item,
                            quantityInGrams: qty,
                          ));
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.surfaceVariant,
                    disabledForegroundColor: AppColors.textTertiary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add to Bill'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filters
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search menu items...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedCategory = cat),
                        backgroundColor: AppColors.surfaceVariant,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? Colors.transparent : AppColors.border),
                        ),
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Menu Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh ?? () async {},
            color: AppColors.primary,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : (constraints.maxWidth > 600 ? 3 : 2);
                final childAspectRatio = constraints.maxWidth > 600 ? 0.8 : 0.72;

                if (_filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off_rounded, size: 56, color: AppColors.textTertiary),
                        SizedBox(height: 16),
                        Text(
                          'No menu items found',
                          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildMenuItemCard(_filteredItems[index], index);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItem item, int index) {
    final bool isOutOfStock = item.stockQuantity <= 0;
    final bool isLowStock = item.stockQuantity < item.lowStockThreshold;
    final String stockText = '${(item.stockQuantity / 1000).toStringAsFixed(1)}kg left';

    return FadeInSlide(
      delay: (index % 10) * 0.04,
      child: ScaleButton(
        onTap: isOutOfStock ? null : () => _openQuantityDialog(item),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLowStock ? AppColors.warning.withOpacity(0.7) : AppColors.border,
              width: isLowStock ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (isLowStock)
                BoxShadow(
                  color: AppColors.warning.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon / Image Header
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isOutOfStock 
                        ? AppColors.surfaceVariant
                        : (isLowStock ? AppColors.warning.withOpacity(0.12) : AppColors.primary.withOpacity(0.12)),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    image: (item.imageUrl.isNotEmpty && !isOutOfStock) 
                        ? DecorationImage(
                            image: NetworkImage(ApiService.formatImageUrl(item.imageUrl)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      if (item.imageUrl.isEmpty || isOutOfStock)
                        Center(
                          child: Opacity(
                            opacity: isOutOfStock ? 0.4 : 1.0,
                            child: Text(
                              item.icon,
                              style: const TextStyle(fontSize: 44),
                            ),
                          ),
                        ),
                      if (isOutOfStock)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.error.withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'OUT OF STOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Item Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isOutOfStock ? AppColors.textSecondary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (!isOutOfStock)
                      Row(
                        children: [
                          Icon(
                            isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                            size: 13,
                            color: isLowStock ? AppColors.warning : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stockText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                              color: isLowStock ? AppColors.warning : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₹${(item.price * 1000).toStringAsFixed(0)}/kg',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock ? AppColors.textSecondary : AppColors.primary,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isOutOfStock ? AppColors.surfaceVariant : AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: isOutOfStock ? [] : [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: isOutOfStock ? AppColors.textTertiary : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
