import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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
      customPattern: 'Rp #,##0',
    );
    return formatter.format(val).replaceAll(',', '.');
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hanya biarkan angka
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
      customPattern: 'Rp #,##0',
    );
    
    double value = double.parse(newText);
    String formatted = formatter.format(value).replaceAll(',', '.');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
