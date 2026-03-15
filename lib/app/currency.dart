/// Formats [amount] as Indian Rupee (₹) with optional comma grouping.
/// Whole numbers show no decimals; others show two.
String formatCurrency(double amount) {
  final isWhole = amount == amount.roundToDouble();
  final value = isWhole
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);
  final parts = value.split('.');
  final intPart = parts[0];
  final sign = intPart.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? intPart : intPart.substring(1);
  final buffer = StringBuffer(sign);
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  if (parts.length > 1) {
    buffer.write('.');
    buffer.write(parts[1]);
  }
  return '₹${buffer.toString()}';
}
