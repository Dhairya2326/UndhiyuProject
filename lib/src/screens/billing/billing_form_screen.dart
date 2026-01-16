import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final qty = double.tryParse(quantityController.text) ?? 0;
            price = qty * item.price;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                   Text(item.icon, style: const TextStyle(fontSize: 24)),
                   const SizedBox(width: 12),
                   Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (grams)',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Price per gram: ₹${item.price.toStringAsFixed(3)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Price:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = double.tryParse(quantityController.text);
                    if (qty == null || qty <= 0) {
                      return; // Show error
                    }
                    
                    // Stock check handled in backend, but good to check here too?
                    // Leaving naive for now as backend validates.
                    
                    widget.onAddToCart(CartItem(
                      menuItem: item,
                      quantityInGrams: qty,
                    ));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search menu items...',
                  prefixIcon: const Icon(Icons.search),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey[100],
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
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
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
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns for mobile
                childAspectRatio: 0.75, // Taller cards
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItemCard(_filteredItems[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    final bool isOutOfStock = item.stockQuantity <= 0;
    final bool isLowStock = item.stockQuantity < item.lowStockThreshold;
    final String stockText = '${(item.stockQuantity / 1000).toStringAsFixed(1)}kg left';

    return GestureDetector(
      onTap: isOutOfStock ? null : () => _openQuantityDialog(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
          border: isLowStock ? Border.all(color: Colors.orange.withOpacity(0.5), width: 2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon / Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isOutOfStock 
                      ? Colors.grey[300] 
                      : (isLowStock ? Colors.orange[50] : AppColors.primaryLight.withOpacity(0.3)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: (item.imageUrl.isNotEmpty && !isOutOfStock) 
                      ? DecorationImage(
                          image: NetworkImage(item.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (item.imageUrl.isEmpty || isOutOfStock)
                      Center(
                        child: Opacity(
                          opacity: isOutOfStock ? 0.5 : 1.0,
                          child: Text(
                            item.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    if (isOutOfStock)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Item Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isOutOfStock ? Colors.grey : AppColors.textPrimary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                    
                     // Stock Status Bar
                    if (!isOutOfStock)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isLowStock ? Colors.red : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isLowStock ? 'Low: $stockText' : stockText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isLowStock ? Colors.red : Colors.grey[600],
                                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Mini Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (item.stockQuantity / 50000).clamp(0.0, 1.0), // Assumes 50kg max for visual
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isLowStock ? Colors.red : Colors.green,
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ],
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price}/g',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
