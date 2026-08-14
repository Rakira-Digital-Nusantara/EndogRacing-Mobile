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
  static const Color primary = Color(0xFF1E88E5); // Biru
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);

  // === Warna Aksen (Secondary) ===
  static const Color secondary = Color(0xFFFF6F00); // Oranye (khas racing)
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFFA726);

  // === Background ===
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFFAFAFA);

  // === Teks ===
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // === Status ===
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF29B6F6);

  // === Divider & Border ===
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
}
