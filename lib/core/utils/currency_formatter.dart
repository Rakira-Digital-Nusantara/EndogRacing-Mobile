import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(dynamic value) {
    if (value == null) return 'Rp 0';
    
    double val = 0.0;
    if (value is int) {
      val = value.toDouble();
    } else if (value is double) {
      val = value;
    } else if (value is String) {
      val = double.tryParse(value) ?? 0.0;
    }
    
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(val);
  }
}
