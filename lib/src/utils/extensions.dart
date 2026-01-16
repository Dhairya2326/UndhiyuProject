extension CurrencyFormatter on double {
  String toCurrency() => '₹${toStringAsFixed(2)}';
}

extension StringParsing on String {
  double toDouble() => double.tryParse(this) ?? 0.0;
}
