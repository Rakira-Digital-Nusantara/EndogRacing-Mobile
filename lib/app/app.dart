import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';

/// Widget utama aplikasi (MaterialApp).
///
/// File ini mengatur:
/// - Tema global (warna, font, Material3).
/// - Routing menggunakan GoRouter.
///
/// Dipisahkan dari main.dart agar main.dart tetap bersih
/// (hanya berisi inisialisasi dan provider).
class App extends StatelessWidget {
  final GoRouter router;

  const App({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EndogRacing',
      debugShowCheckedModeBanner: false,

      // === Tema Aplikasi ===
      theme: ThemeData(
        fontFamily: 'VisbyRoundCF',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,

        // Kustomisasi AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),

        // Kustomisasi Input (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),

      // === Routing ===
      routerConfig: router,
    );
  }
}
