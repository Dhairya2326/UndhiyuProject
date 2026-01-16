import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';

class BillingFormScreen extends StatefulWidget {
  final List<MenuItem> menuItems;
  final Function(CartItem) onAddToCart;
  final List<CartItem> cartItems;

  const BillingFormScreen({
    super.key,
    required this.menuItems,
    required this.onAddToCart,
    required this.cartItems,
  });

  @override
  State<BillingFormScreen> createState() => _BillingFormScreenState();
}

class _BillingFormScreenState extends State<BillingFormScreen> {
  MenuItem? _selectedItem;
  final _quantityController = TextEditingController();
  double _calculatedPrice = 0;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _calculatePrice() {
    if (_selectedItem == null) return;
    
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _calculatedPrice = quantity * _selectedItem!.price;
    });
  }

  void _addItemToBill() {
    if (_selectedItem == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item and enter quantity')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
      return;
    }

    // Convert quantity to grams (assuming quantity is in kg)
    final quantityInGrams = quantity * 1000;
    final cartItem = CartItem(
      menuItem: _selectedItem!,
      quantityInGrams: quantityInGrams,
    );

    widget.onAddToCart(cartItem);

    // Reset form
    setState(() {
      _selectedItem = null;
      _quantityController.clear();
      _calculatedPrice = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedItem?.name} added to bill!'),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Form Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Item to Bill',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Item Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<MenuItem>(
                        isExpanded: true,
                        value: _selectedItem,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Select Item'),
                        ),
                        onChanged: (MenuItem? newValue) {
                          setState(() {
                            _selectedItem = newValue;
                            _quantityController.clear();
                            _calculatedPrice = 0;
                          });
                        },
                        items: widget.menuItems.map<DropdownMenuItem<MenuItem>>(
                          (MenuItem item) {
                            return DropdownMenuItem<MenuItem>(
                              value: item,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      item.icon,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            '₹${item.price.toStringAsFixed(2)}/g',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),

                    if (_selectedItem != null) ...[
                      const SizedBox(height: 16),

                      // Price per kg (locked field)
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Price per gram',
                          hintText: '₹${_selectedItem!.price.toStringAsFixed(2)}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixText: '₹/kg',
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Metric (locked field)
                      TextField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Metric',
                          hintText: 'kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixText: 'kg',
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Quantity Input
                      TextField(
                        controller: _quantityController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          hintText: 'Enter quantity in kg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixText: 'kg',
                          prefixIcon: const Icon(Icons.scale),
                        ),
                        onChanged: (_) => _calculatePrice(),
                      ),

                      const SizedBox(height: 16),

                      // Calculated Price Display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Price:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '₹${_calculatedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Add Item Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addItemToBill,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Add Item to Bill'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Cart Preview Section
          if (widget.cartItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Items in Bill (${widget.cartItems.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = widget.cartItems[index];
                final item = cartItem.menuItem;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: ListTile(
                      leading: Text(item.icon, style: const TextStyle(fontSize: 24)),
                      title: Text(item.name),
                      subtitle: Text(
                        '${cartItem.quantityInGrams.toStringAsFixed(0)}g (${cartItem.quantityInKg.toStringAsFixed(2)}kg) × ₹${item.price.toStringAsFixed(2)}/g',
                      ),
                      trailing: Text(
                        '₹${cartItem.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
