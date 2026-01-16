import 'package:url_launcher/url_launcher.dart';
import 'package:undhiyuapp/src/models/billing_model.dart';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  
  final List<Transaction> _transactions = [];

  factory BillingService() {
    return _instance;
  }

  BillingService._internal();

  double calculateTotal(double price, double quantity) {
    return price * quantity;
  }

  void recordTransaction({required double amount, required String method}) {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      paymentMethod: method,
      timestamp: DateTime.now(),
    );
    _transactions.add(transaction);
  }

  List<Transaction> getTransactionHistory() {
    return _transactions;
  }

  Future<void> payWithUPI(double amount) async {
    final upiUrl =
        "upi://pay?pa=yourupi@bank&pn=Undhiyu%20Shop&am=${amount.toStringAsFixed(2)}&cu=INR";

    final uri = Uri.parse(upiUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      throw Exception('Failed to launch UPI: $e');
    }
  }
}
