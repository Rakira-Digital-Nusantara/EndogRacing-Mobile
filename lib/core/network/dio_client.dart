import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
/// DioClient adalah konfigurasi HTTP Client utama aplikasi.
///
/// Class ini bertanggung jawab untuk:
/// 1. Mengatur Base URL dari file `.env`.
/// 2. Menambahkan token (Bearer Token) secara otomatis ke setiap request.
/// 3. Menangkap error 401 (token expired) → agar bisa auto-logout.
///
/// Contoh penggunaan:
/// ```dart
/// final dioClient = DioClient();
/// final response = await dioClient.dio.get('/me');
/// ```
class DioClient {
  static const String baseUrl = 'https://api-endogracing.rakiradigital.com/api';
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        // Header default yang dikirim ke Laravel
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    // Pasang interceptor (penyadap) untuk request dan response
    dio.interceptors.add(
      InterceptorsWrapper(
        // --- SEBELUM REQUEST DIKIRIM ---
        // Otomatis menambahkan token ke header setiap request.
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔑 DIO_CLIENT: Mengirim token (Length: ${token.length}) ke ${options.path}');
          } else {
            debugPrint('⚠️ DIO_CLIENT: Token KOSONG saat memanggil ${options.path}');
          }
          handler.next(options); // Lanjutkan request
        },
        // --- SAAT MENERIMA RESPONSE ---
        onResponse: (response, handler) {
          handler.next(response); // Lanjutkan response seperti biasa
        },
        // --- SAAT TERJADI ERROR ---
        onError: (DioException error, handler) async {
          final context = rootNavigatorKey.currentContext;
          
          if (error.response?.statusCode == 401) {
            // Token Mati / Unauthorized
            await _storage.delete(key: 'auth_token');
            if (context != null) {
              // Redirect ke halaman role-selection via GoRouter
              context.go('/role-selection');
            }
          } else if (error.response?.statusCode == 429) {
            // Rate Limiting
            if (context != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terlalu banyak percobaan. Silakan tunggu 1 menit.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } else if (error.response?.statusCode == 403) {
            // Forbidden / IDOR
            if (context != null) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Akses Ditolak'),
                  content: const Text('Ini bukan transaksi Anda.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
          handler.next(error); // Teruskan error ke pemanggil
        },
      ),
    );
  }
}
