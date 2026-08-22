import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  
  // Image picker state
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isUploadingImage = false;
  
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  final List<String> _categories = ['Main Dish', 'Beverages', 'Desserts', 'Snacks', 'Other'];

  // Settings State
  final _paymentNameController = TextEditingController();
  final _paymentImageUrlController = TextEditingController();
  Uint8List? _paymentImageBytes;
  String? _paymentImageName;
  bool _isLoadingSettings = false;

  // Dashboard State
  Map<String, dynamic> _salesSummary = {};
  bool _isLoadingDashboard = false;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
    _loadPaymentConfig();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final summary = await _apiService.fetchSalesSummary();
      if (mounted) {
        setState(() {
          _salesSummary = summary;
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
        // Silently fail or show snackbar? Let's just log it for now
        debugPrint('Error loading dashboard: $e');
      }
    }
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
    _paymentNameController.dispose();
    _paymentImageUrlController.dispose();
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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _imageUrlController.clear();
    });
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
      String? imageUrl;
      
      // Upload image if selected
      if (_selectedImageBytes != null && _selectedImageName != null) {
        setState(() => _isUploadingImage = true);
        try {
          imageUrl = await _apiService.uploadImage(
            imageBytes: _selectedImageBytes!,
            filename: _selectedImageName!,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Image upload failed: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      } else if (_imageUrlController.text.isNotEmpty) {
        imageUrl = _imageUrlController.text;
      }
      
      await _apiService.addMenuItem(
        name: _nameController.text,
        category: _selectedCategory,
        price: double.parse(_priceController.text),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'No description',
        icon: _iconController.text.isNotEmpty ? _iconController.text : '🍽️',
        imageUrl: imageUrl ?? '',
      );

      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _iconController.clear();
      _imageUrlController.clear();
      _clearSelectedImage();
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

  Future<void> _loadPaymentConfig() async {
    setState(() => _isLoadingSettings = true);
    try {
      final config = await _apiService.fetchPaymentConfig();
      if (config.isNotEmpty) {
        _paymentNameController.text = config['upiName'] ?? '';
        _paymentImageUrlController.text = config['qrCodeUrl'] ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _pickPaymentImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _paymentImageBytes = bytes;
          _paymentImageName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _savePaymentSettings() async {
    if (_paymentNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Payee Name')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = _paymentImageUrlController.text;

      // Upload image if selected
      if (_paymentImageBytes != null && _paymentImageName != null) {
        setState(() => _isUploadingImage = true);
        try {
          imageUrl = await _apiService.uploadImage(
            imageBytes: _paymentImageBytes!,
            filename: _paymentImageName!,
          );
        } catch (e) {
          throw Exception('Image upload failed: $e');
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      }

      await _apiService.updatePaymentConfig({
        'upiName': _paymentNameController.text,
        'qrCodeUrl': imageUrl ?? '',
      });
      
      // Update controller with new URL if uploaded
      if (imageUrl != null) {
        _paymentImageUrlController.text = imageUrl;
        setState(() {
          _paymentImageBytes = null;
          _paymentImageName = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ... (existing helper methods like _loadMenuItems)

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
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildTabButton('Dashboard', 0),
                _buildTabButton('Add Item', 1),
                _buildTabButton('Inventory', 2),
                _buildTabButton('Settings', 3),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(_tabIndex),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tabIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildAddTab();
      case 2:
        return _buildManageTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildDashboardTab();
    }
  }
  
  // ... (existing _buildTabButton, _buildAddTab, _buildManageTab)

  Widget _buildSettingsTab() {
    if (_isLoadingSettings) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final hasPreviewImage = _paymentImageBytes != null || _paymentImageUrlController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment & QR Configuration', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Configure the UPI QR Code and Payee Name displayed on the customer billing screen.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          TextField(
            controller: _paymentNameController,
            decoration: const InputDecoration(
              labelText: 'Payee Name / UPI ID *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person, color: AppColors.primary),
              hintText: 'e.g. Shivam Caterers / username@upi',
            ),
          ),
          const SizedBox(height: 20),

          // QR Image Configuration Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_2, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('UPI QR Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const Spacer(),
                    if (hasPreviewImage)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _paymentImageBytes = null;
                            _paymentImageName = null;
                            _paymentImageUrlController.clear();
                          });
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // QR Preview Area
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _paymentImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_paymentImageBytes!, fit: BoxFit.contain),
                          )
                        : (_paymentImageUrlController.text.trim().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ApiService.formatImageUrl(_paymentImageUrlController.text.trim()),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('Invalid Image URL', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.black54),
                                  SizedBox(height: 6),
                                  Text('No QR Code Set', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              )),
                  ),
                ),
                const SizedBox(height: 18),

                // Option 1: Internet Image URL
                TextField(
                  controller: _paymentImageUrlController,
                  decoration: InputDecoration(
                    labelText: 'QR Code Image URL (Internet)',
                    hintText: 'https://example.com/qr-code.png',
                    prefixIcon: const Icon(Icons.link, color: AppColors.primary),
                    suffixIcon: _paymentImageUrlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _paymentImageUrlController.clear()),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Option 2: Upload from Device
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR', style: TextStyle(color: AppColors.textTertiary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickPaymentImage,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_paymentImageName != null ? 'Change File (${_paymentImageName!})' : 'Upload QR Image from Device'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 28),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _savePaymentSettings,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSubmitting ? 'Saving...' : 'Save Configuration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDashboardTab() {
    if (_isLoadingDashboard) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final totalRevenue = (_salesSummary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalBills = _salesSummary['totalBills'] as int? ?? 0;
    final avgOrder = (_salesSummary['averageOrderValue'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInSlide(
              delay: 0,
              child: const Text(
                'Business Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            
            // Revenue Card
            FadeInSlide(
              delay: 0.1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Revenue',
                      style: TextStyle(color: Colors.black54, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalRevenue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            FadeInSlide(
              delay: 0.2,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Orders',
                      totalBills.toString(),
                      Icons.receipt_long,
                      const Color(0xFF5C6BC0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Avg. Order',
                      '₹${avgOrder.toStringAsFixed(0)}',
                      Icons.analytics,
                      AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
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
    final hasImage = _selectedImageBytes != null || _imageUrlController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Menu Item', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          const Text('Create a new dish with internet image URL, description, and pricing.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant_menu, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
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
              prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Price per gram (₹) *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primary),
              hintText: 'e.g., 0.35 (which equals ₹350/kg)',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description_outlined, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          
          // Image Picker / URL Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.image, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Item Image', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const Spacer(),
                    if (hasImage)
                      TextButton.icon(
                        onPressed: _clearSelectedImage,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Clear Image'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Live Image Preview
                if (hasImage)
                  Center(
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _selectedImageBytes != null
                            ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                            : Image.network(
                                ApiService.formatImageUrl(_imageUrlController.text.trim()),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                                    SizedBox(height: 4),
                                    Text('Unable to load image from URL', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),

                // Option 1: Internet Image URL
                TextField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Image URL from Internet',
                    hintText: 'https://images.unsplash.com/... or any image link',
                    prefixIcon: const Icon(Icons.link, color: AppColors.primary),
                    suffixIcon: _imageUrlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _imageUrlController.clear()),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Option 2: Upload Image File
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('OR', style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(_selectedImageName != null ? 'Selected: ${_selectedImageName!}' : 'Upload Image from Device'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _addMenuItem,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(_isSubmitting ? 'Adding...' : 'Add Menu Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Error: $_error', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMenuItems,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final stockKg = item.stockQuantity / 1000;
        final isLowStock = item.stockQuantity < item.lowStockThreshold;

        return FadeInSlide(
          delay: (index % 10) * 0.04,
          child: ScaleButton(
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isLowStock ? AppColors.warning.withOpacity(0.6) : AppColors.border,
                  width: isLowStock ? 1.5 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Image / Icon Container
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                ApiService.formatImageUrl(item.imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Text(item.icon, style: const TextStyle(fontSize: 28)),
                                ),
                              )
                            : Center(
                                child: Text(item.icon, style: const TextStyle(fontSize: 28)),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.category,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          // Stock Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isLowStock
                                  ? AppColors.warning.withOpacity(0.15)
                                  : AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isLowStock ? AppColors.warning.withOpacity(0.4) : AppColors.success.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                  size: 13,
                                  color: isLowStock ? AppColors.warning : AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${stockKg.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    color: isLowStock ? AppColors.warning : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
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
                          '₹${(item.price * 1000).toStringAsFixed(0)}/kg',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _editMenuItem(item),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.edit, color: AppColors.primary, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _deleteMenuItem(item.id),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
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

  Future<void> _editMenuItem(MenuItem item) async {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final descriptionController = TextEditingController(text: item.description);
    final imageUrlController = TextEditingController(text: item.imageUrl);
    final stockController = TextEditingController(text: (item.stockQuantity / 1000).toString());
    final thresholdController = TextEditingController(text: (item.lowStockThreshold / 1000).toString());
    String selectedCat = item.category;
    Uint8List? editImageBytes;
    String? editImageName;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasImg = editImageBytes != null || imageUrlController.text.trim().isNotEmpty;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.edit_note, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Edit: ${item.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Item Name *', isDense: true),
                      ),
                      const SizedBox(height: 12),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _categories.contains(selectedCat) ? selectedCat : _categories.first,
                        items: _categories
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedCat = val ?? selectedCat),
                        decoration: const InputDecoration(labelText: 'Category', isDense: true),
                      ),
                      const SizedBox(height: 12),

                      // Price per gram
                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price per gram (₹) *',
                          hintText: 'e.g. 0.35',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description', isDense: true),
                      ),
                      const SizedBox(height: 14),

                      // Image Section Header
                      const Text('Dish Image', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
                      const SizedBox(height: 8),

                      if (hasImg)
                        Container(
                          height: 120,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: editImageBytes != null
                                ? Image.memory(editImageBytes!, fit: BoxFit.cover)
                                : Image.network(
                                    ApiService.formatImageUrl(imageUrlController.text.trim()),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey),
                                    ),
                                  ),
                          ),
                        ),

                      // Image URL input
                      TextField(
                        controller: imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'Image URL from Internet',
                          hintText: 'https://...',
                          prefixIcon: const Icon(Icons.link, size: 18),
                          suffixIcon: imageUrlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setDialogState(() => imageUrlController.clear()),
                                )
                              : null,
                          isDense: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 8),

                      // Upload Device Image button
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final XFile? pickedFile = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 85,
                            );
                            if (pickedFile != null) {
                              final bytes = await pickedFile.readAsBytes();
                              setDialogState(() {
                                editImageBytes = bytes;
                                editImageName = pickedFile.name;
                              });
                            }
                          } catch (e) {
                            debugPrint('Error picking edit image: $e');
                          }
                        },
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: Text(editImageName != null ? 'Selected: $editImageName' : 'Upload from Device', style: const TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 38),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Stock Inputs
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Stock (kg)', isDense: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: thresholdController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Low Alert (kg)', isDense: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      String? finalImageUrl = imageUrlController.text.trim();

                      if (editImageBytes != null && editImageName != null) {
                        final uploadedUrl = await _apiService.uploadImage(
                          imageBytes: editImageBytes!,
                          filename: editImageName!,
                        );
                        finalImageUrl = uploadedUrl;
                      }

                      final newStock = (double.tryParse(stockController.text) ?? 0) * 1000;
                      final newThreshold = (double.tryParse(thresholdController.text) ?? 0) * 1000;
                      final newPrice = double.tryParse(priceController.text) ?? item.price;

                      await _apiService.updateMenuItem(
                        id: item.id,
                        updates: {
                          'name': nameController.text.trim(),
                          'category': selectedCat,
                          'price': newPrice,
                          'description': descriptionController.text.trim(),
                          'imageUrl': finalImageUrl,
                          'stockQuantity': newStock,
                          'lowStockThreshold': newThreshold,
                        },
                      );
                      
                      if (context.mounted) Navigator.pop(context);
                      _loadMenuItems();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMenuItem(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
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
}
