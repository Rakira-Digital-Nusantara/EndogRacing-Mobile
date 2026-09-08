import 'package:flutter/material.dart';

/// Palet warna aplikasi EndogRacing.
///
/// Gunakan class ini untuk menjaga konsistensi warna
/// di seluruh aplikasi. Jangan gunakan warna hardcoded
/// langsung di widget.
///
/// Contoh penggunaan:
/// ```dart
/// Container(color: AppColors.primary)
/// Text('Hello', style: TextStyle(color: AppColors.textPrimary))
/// ```
class AppColors {
  AppColors._(); // Private constructor, class ini tidak perlu di-instantiate

  // === Warna Utama (Primary) ===
  static const Color primary = Color(0xFF0D47A1); // Biru Gelap
  static const Color primaryDark = Color(0xFF002171); // Biru Sangat Gelap
  static const Color primaryLight = Color(0xFF5472D3); // Biru Terang

  // === Warna Aksen (Secondary) ===
  static const Color secondary = Color(0xFF0288D1); // Biru Muda / Cyan
  static const Color secondaryDark = Color(0xFF005B9F);
  static const Color secondaryLight = Color(0xFF5EB8FF);

  // === Background ===
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF1F5F9); // Abu-abu terang netral (Slate-100)
  static const Color scaffoldBackground = Colors.white;

  // === Teks ===
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textHint = Colors.black38;
  static const Color textOnPrimary = Colors.white;

  // === Status ===
  static const Color success = Colors.green;
  static const Color warning = Colors.amber;
  static const Color error = Colors.red;
  static const Color info = Colors.lightBlue;

  // === Divider & Border ===
  static const Color divider = Colors.grey;
  static const Color border = Colors.grey;
}

