class BillingModel {
  final double price;
  final double quantity;

  BillingModel({required this.price, required this.quantity});

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'quantity': quantity,
      'total': total,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  factory BillingModel.fromJson(Map<String, dynamic> json) {
    return BillingModel(
      price: json['price'] ?? 0.0,
      quantity: json['quantity'] ?? 0.0,
    );
  }
}

class Transaction {
  final String id;
  final double amount;
  final String paymentMethod;
  final DateTime timestamp;

  Transaction({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
