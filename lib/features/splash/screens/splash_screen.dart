import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulasi loading 4 detik sebelum masuk ke role selection
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.go('/role-selection');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Wallpaper
          Image.asset(
            'assets/images/Wallpaper HP1.png',
            fit: BoxFit.cover,
          ),
          
          // Content Tengah
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo dengan background putih membulat (opsional, jika logo transparan)
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    'assets/images/Logo Endog Racing Hijau.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Teks ENDOG RACING
              const Text(
                'ENDOG RACING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              
              // Teks MANAJEMEN KANDANG
              const Text(
                'MANAJEMEN KANDANG',
                style: TextStyle(
                  color: Color(0xFF65A30D), // Hijau muda (bisa disesuaikan dengan AppColors)
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4.0,
                ),
              ),
            ],
          ),
          
          // Progress Bar dan Teks Bawah
          Positioned(
            bottom: 48,
            left: 48,
            right: 48,
            child: Column(
              children: [
                // Custom Progress Bar statis (bisa dibuat animasi jika perlu)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 8,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.2), // Background track
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 4), // Animasi penuh dalam 4 detik
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF84CC16), // Hijau terang
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SIAP DIGUNAKAN',
                  style: TextStyle(
                    color: Color(0xFF65A30D),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
