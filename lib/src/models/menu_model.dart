class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final String icon;
  final String imageUrl;
  final bool available;
  final double stockQuantity; // in grams
  final double lowStockThreshold; // in grams
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.icon,
    this.imageUrl = '',
    this.available = true,
    this.stockQuantity = 0,
    this.lowStockThreshold = 0,
    this.createdAt,
    this.updatedAt,
  });
}

class CartItem {
  final MenuItem menuItem;
  double quantityInGrams; // Quantity in grams

  CartItem({
    required this.menuItem,
    this.quantityInGrams = 1000, // Default 1kg (1000 grams)
  });

  // Calculate total price: grams * price_per_gram
  double get totalPrice => quantityInGrams * menuItem.price;

  double get quantityInKg => quantityInGrams / 1000;

  void addGrams(double grams) => quantityInGrams += grams;

  void removeGrams(double grams) {
    quantityInGrams -= grams;
    if (quantityInGrams < 0) quantityInGrams = 0;
  }
}

class MenuData {
  // Helper method to filter items by category
  static List<MenuItem> getItemsByCategory(List<MenuItem> items, String category) {
    return items.where((item) => item.category == category).toList();
  }

  // Helper method to get all unique categories from items
  static List<String> getCategories(List<MenuItem> items) {
    final categories = <String>{};
    for (var item in items) {
      categories.add(item.category);
    }
    return categories.toList();
  }

  // Helper method to find item by ID
  static MenuItem? getMenuItemById(List<MenuItem> items, String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
