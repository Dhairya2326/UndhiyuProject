import 'package:flutter/material.dart';
import 'package:undhiyuapp/src/constants/app_colors.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/services/api_service.dart';
import 'package:undhiyuapp/src/widgets/animations/fade_in_slide.dart';
import 'package:undhiyuapp/src/widgets/animations/scale_button.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _apiService = ApiService();
  int _tabIndex = 0;
  
  // Controllers for Adding
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _iconController = TextEditingController();
  final _imageUrlController = TextEditingController(); // NEW
  final _stockController = TextEditingController(text: '50'); // Default 50kg
  final _thresholdController = TextEditingController(text: '5'); // Default 5kg
  
  String _selectedCategory = 'Main Dish';
  
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  final List<String> _categories = ['Main Dish', 'Beverages', 'Desserts', 'Snacks', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _iconController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _apiService.fetchMenuItems();
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addMenuItem() async {
    // Removed Icon validation as requested
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Name and Price fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiService.addMenuItem(
        name: _nameController.text,
        category: _selectedCategory,
        price: double.parse(_priceController.text),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'No description',
        icon: _iconController.text.isNotEmpty ? _iconController.text : '🍽️',
        imageUrl: _imageUrlController.text, // Pass Image URL
      );

      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _iconController.clear();
      _imageUrlController.clear();
      _selectedCategory = 'Main Dish';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item added!')),
        );
      }

      await _loadMenuItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateStock(MenuItem item) async {
    final stockController = TextEditingController(text: (item.stockQuantity / 1000).toString());
    final thresholdController = TextEditingController(text: (item.lowStockThreshold / 1000).toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current Stock (kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Low Stock Alert Threshold (kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
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
            onPressed: () async {
              try {
                final newStock = (double.tryParse(stockController.text) ?? 0) * 1000;
                final newThreshold = (double.tryParse(thresholdController.text) ?? 0) * 1000;

                await _apiService.updateMenuItem(
                  id: item.id,
                  updates: {
                    'stockQuantity': newStock,
                    'lowStockThreshold': newThreshold,
                  },
                );
                
                if (mounted) Navigator.pop(context);
                _loadMenuItems();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMenuItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _apiService.deleteMenuItem(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item deleted!')),
          );
        }
        await _loadMenuItems();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Admin Portal'),
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Go Back',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton('Add Item', 0),
                _buildTabButton('Manage Inventory', 1),
              ],
            ),
          ),
          Expanded(
            child: _tabIndex == 0 ? _buildAddTab() : _buildManageTab(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String title, int index) {
    final bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.textSecondary,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Menu Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            items: _categories
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value ?? 'Main Dish');
            },
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per gram (₹) *',
              border: OutlineInputBorder(),
              hintText: 'e.g., 0.15',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _iconController,
                  decoration: const InputDecoration(
                    labelText: 'Icon/Emoji (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 🥘',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'https://...',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _addMenuItem,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: Text(_isSubmitting ? 'Adding...' : 'Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            Text('Error: $_error'),
            ElevatedButton(onPressed: _loadMenuItems, child: const Text('Retry')),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final stockKg = item.stockQuantity / 1000;
        final isLowStock = item.stockQuantity < item.lowStockThreshold;

        return FadeInSlide(
          delay: index * 0.05, // Staggered animation
          child: ScaleButton(
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Image/Icon Container
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        image: item.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(item.imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.imageUrl.isEmpty
                          ? Center(
                              child: Text(item.icon,
                                  style: const TextStyle(fontSize: 28)))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          // Stock Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLowStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline,
                                  size: 14,
                                  color: isLowStock
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${stockKg.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    color: isLowStock
                                        ? AppColors.error
                                        : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Price & Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.price.toStringAsFixed(3)}/g',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _updateStock(item),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.edit_note,
                                    color: AppColors.primary, size: 20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _deleteMenuItem(item.id),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
