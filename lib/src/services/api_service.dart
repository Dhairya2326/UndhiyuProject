import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:undhiyuapp/src/models/menu_model.dart';
import 'package:undhiyuapp/src/models/bill_history_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  // Change this to your backend URL
  static const String baseUrl = 'http://192.168.29.108:5000/api/v1';
  
  // For production, use:
  // static const String baseUrl = 'https://your-production-url.com/api/v1';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  // ==================== MENU ENDPOINTS ====================

  /// Fetch all menu items from backend
  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menu'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((item) => MenuItem(
                    id: item['id'],
                    name: item['name'],
                    category: item['category'],
                    price: (item['price'] as num).toDouble(),
                    description: item['description'] ?? '',
                    icon: item['icon'] ?? '🍽️',
                    imageUrl: item['imageUrl'] ?? '',
                    stockQuantity: (item['stockQuantity'] as num?)?.toDouble() ?? 0,
                    lowStockThreshold: (item['lowStockThreshold'] as num?)?.toDouble() ?? 0,
                  ))
              .toList();
          return items;
        }
      }
      throw Exception('Failed to fetch menu items');
    } catch (e) {
      throw Exception('Error fetching menu items: $e');
    }
  }

  /// Fetch menu items by category
  Future<List<MenuItem>> fetchMenuItemsByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menu/category/$category'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final items = (data['data'] as List)
              .map((item) => MenuItem(
                    id: item['id'],
                    name: item['name'],
                    category: item['category'],
                    price: (item['price'] as num).toDouble(),
                    description: item['description'] ?? '',
                    icon: item['icon'] ?? '🍽️',
                    stockQuantity: (item['stockQuantity'] as num?)?.toDouble() ?? 0,
                    lowStockThreshold: (item['lowStockThreshold'] as num?)?.toDouble() ?? 0,
                  ))
              .toList();
          return items;
        }
      }
      throw Exception('Failed to fetch menu items by category');
    } catch (e) {
      throw Exception('Error fetching menu items: $e');
    }
  }

  /// Fetch all categories
  Future<List<String>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menu/categories'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<String>.from(data['data'] as List);
        }
      }
      throw Exception('Failed to fetch categories');
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  /// Add new menu item
  Future<MenuItem> addMenuItem({
    required String name,
    required String category,
    required double price,
    String description = '',
    String icon = '🍽️',
    String imageUrl = '',
  }) async {
    try {
      final body = jsonEncode({
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'icon': icon,
        'imageUrl': imageUrl,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/menu'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return MenuItem(
            id: data['data']['id'],
            name: data['data']['name'],
            category: data['data']['category'],
            price: (data['data']['price'] as num).toDouble(),
            description: data['data']['description'] ?? '',
            icon: data['data']['icon'] ?? '🍽️',
            imageUrl: data['data']['imageUrl'] ?? '',
            stockQuantity: (data['data']['stockQuantity'] as num?)?.toDouble() ?? 0,
            lowStockThreshold: (data['data']['lowStockThreshold'] as num?)?.toDouble() ?? 0,
          );
        }
      }
      throw Exception('Failed to add menu item');
    } catch (e) {
      throw Exception('Error adding menu item: $e');
    }
  }

  /// Update menu item
  Future<MenuItem> updateMenuItem({
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/menu/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updates),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return MenuItem(
            id: data['data']['id'],
            name: data['data']['name'],
            category: data['data']['category'],
            price: (data['data']['price'] as num).toDouble(),
            description: data['data']['description'] ?? '',
            icon: data['data']['icon'] ?? '🍽️',
            imageUrl: data['data']['imageUrl'] ?? '',
            stockQuantity: (data['data']['stockQuantity'] as num?)?.toDouble() ?? 0,
            lowStockThreshold: (data['data']['lowStockThreshold'] as num?)?.toDouble() ?? 0,
          );
        }
      }
      throw Exception('Failed to update menu item');
    } catch (e) {
      throw Exception('Error updating menu item: $e');
    }
  }

  /// Delete menu item
  Future<bool> deleteMenuItem(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/menu/$id'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      throw Exception('Failed to delete menu item');
    } catch (e) {
      throw Exception('Error deleting menu item: $e');
    }
  }

  // ==================== BILLING ENDPOINTS ====================

  /// Create a new bill
  Future<BillRecord> createBill({
    required List<CartItem> cartItems,
    double discount = 0,
    String paymentMethod = 'cash',
    String notes = '',
  }) async {
    try {
      final body = jsonEncode({
        'cartItems': cartItems
            .map((item) => {
                  'menuItem': {
                    'id': item.menuItem.id,
                    'name': item.menuItem.name,
                    'category': item.menuItem.category,
                    'price': item.menuItem.price,
                    'description': item.menuItem.description,
                    'icon': item.menuItem.icon,
                  },
                  'quantityInGrams': item.quantityInGrams,
                })
            .toList(),
        'discount': discount,
        'paymentMethod': paymentMethod,
        'notes': notes,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/billing/create'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return BillRecord.fromJson(data['data']);
        }
      }
      throw Exception('Failed to create bill');
    } catch (e) {
      throw Exception('Error creating bill: $e');
    }
  }

  /// Fetch all bills
  Future<List<BillRecord>> fetchAllBills() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/billing/all'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final bills = (data['data'] as List)
              .map((bill) => BillRecord.fromJson(bill))
              .toList();
          return bills;
        }
      }
      throw Exception('Failed to fetch bills');
    } catch (e) {
      throw Exception('Error fetching bills: $e');
    }
  }

  /// Fetch bill by ID
  Future<BillRecord> fetchBillById(String billId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/billing/$billId'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return BillRecord.fromJson(data['data']);
        }
      }
      throw Exception('Failed to fetch bill');
    } catch (e) {
      throw Exception('Error fetching bill: $e');
    }
  }

  /// Fetch bills by date range
  Future<List<BillRecord>> fetchBillsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final start = startDate.toIso8601String();
      final end = endDate.toIso8601String();
      final response = await http.get(
        Uri.parse('$baseUrl/billing/range/$start/$end'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final bills = (data['data'] as List)
              .map((bill) => BillRecord.fromJson(bill))
              .toList();
          return bills;
        }
      }
      throw Exception('Failed to fetch bills by date range');
    } catch (e) {
      throw Exception('Error fetching bills: $e');
    }
  }

  /// Fetch bills by payment method
  Future<List<BillRecord>> fetchBillsByPaymentMethod(
    String paymentMethod,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/billing/method/$paymentMethod'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final bills = (data['data'] as List)
              .map((bill) => BillRecord.fromJson(bill))
              .toList();
          return bills;
        }
      }
      throw Exception('Failed to fetch bills by payment method');
    } catch (e) {
      throw Exception('Error fetching bills: $e');
    }
  }

  /// Fetch sales summary
  Future<Map<String, dynamic>> fetchSalesSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/billing/summary/sales'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Failed to fetch sales summary');
    } catch (e) {
      throw Exception('Error fetching sales summary: $e');
    }
  }

  /// Fetch most sold items
  Future<List<Map<String, dynamic>>> fetchMostSoldItems({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/billing/summary/top-items?limit=$limit'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      throw Exception('Failed to fetch most sold items');
    } catch (e) {
      throw Exception('Error fetching most sold items: $e');
    }
  }

  /// Delete bill
  Future<bool> deleteBill(String billId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/billing/$billId'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      throw Exception('Failed to delete bill');
    } catch (e) {
      throw Exception('Error deleting bill: $e');
    }
  }




  /// Check backend health
  Future<bool> checkBackendHealth() async {
    try {
      // Remove '/api/v1' from baseUrl to get base server URL
      final healthUrl = baseUrl.replaceAll('/api/v1', '');
      final response = await http.get(
        Uri.parse('$healthUrl/health'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Request timeout'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== UPLOAD ENDPOINTS ====================

  /// Upload an image file and return the URL
  /// For web: pass bytes and filename
  /// For mobile: pass bytes and filename from image_picker
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      // Determine mime type from filename
      String mimeType = 'image/jpeg';
      if (filename.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (filename.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Upload timeout'),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Return the full URL to the uploaded image
          final serverUrl = baseUrl.replaceAll('/api/v1', '');
          return '$serverUrl${data['data']['imageUrl']}';
        }
      }
      throw Exception('Failed to upload image');
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
  // ==================== SETTINGS ENDPOINTS ====================

  /// Fetch payment configuration
  Future<Map<String, dynamic>> fetchPaymentConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/payment_config'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      } else if (response.statusCode == 404) {
         // Return empty config if not set yet
         return {};
      }
      throw Exception('Failed to fetch payment config');
    } catch (e) {
      // Return empty map on error to avoid blocking UI
      print('Error fetching payment config: $e');
      return {};
    }
  }

  /// Update payment configuration
  Future<Map<String, dynamic>> updatePaymentConfig(Map<String, dynamic> config) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings/payment_config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': config}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Failed to update payment config');
    } catch (e) {
      throw Exception('Error updating payment config: $e');
    }
  }
}
