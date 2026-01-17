class BillRecord {
  final String id;
  final DateTime timestamp;
  final List<BillItem> items;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String paymentMethod; // 'cash', 'upi', 'card', 'check', 'other'
  final String notes;
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BillRecord({
    required this.id,
    required this.timestamp,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.totalAmount,
    required this.paymentMethod,
    this.notes = '',
    this.status = 'completed',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory BillRecord.fromJson(Map<String, dynamic> json) {
    return BillRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      items: (json['items'] as List)
          .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

class BillItem {
  final String itemName;
  final String icon;
  final double quantityInGrams;
  final double pricePerGram;
  final double totalPrice;

  BillItem({
    required this.itemName,
    required this.icon,
    required this.quantityInGrams,
    required this.pricePerGram,
    required this.totalPrice,
  });

  double get quantityInKg => quantityInGrams / 1000;

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'icon': icon,
      'quantityInGrams': quantityInGrams,
      'pricePerGram': pricePerGram,
      'totalPrice': totalPrice,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      itemName: json['itemName'] as String,
      icon: json['icon'] as String,
      quantityInGrams: (json['quantityInGrams'] as num).toDouble(),
      pricePerGram: (json['pricePerGram'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }
}
