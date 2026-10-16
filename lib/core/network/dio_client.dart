import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/router.dart';
import '../../features/auth/providers/auth_provider.dart';
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
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint('🔑 DIO_CLIENT: Mengirim token (Length: ${token.length}) ke ${options.path}');
          } else {
            // Jika memanggil /logout tetapi token sudah tidak ada, selesaikan secara lokal tanpa request ke server
            if (options.path.contains('logout')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'message': 'Sudah logout'},
                ),
              );
            }
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
            // Jangan memproses 401 jika request yang gagal adalah request logout itu sendiri (mencegah loop)
            if (error.requestOptions.path.contains('logout')) {
              handler.next(error);
              return;
            }

            // Token Mati / Unauthorized / Expired
            await _storage.delete(key: 'auth_token');
            if (context != null && context.mounted) {
              try {
                // Update state AuthProvider agar GoRouter tidak loop balik ke /home
                context.read<AuthProvider>().handleSessionExpired();
              } catch (_) {}

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesi login telah berakhir. Silakan login kembali.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );

              // Redirect ke halaman role-selection via GoRouter
              context.go('/role-selection');
            }
          } else if (error.response?.statusCode == 429) {
            // Rate Limiting
            if (context != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terlalu banyak percobaan. Silakan tunggu 1 menit.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          } else if (error.response?.statusCode == 403) {
            // Cek apakah error 403 adalah validasi operasional yang ditangani layar (misal Belum Absen)
            final data = error.response?.data;
            final message = (data is Map ? (data['message'] ?? data['error']) : null)?.toString() ?? '';
            final isBusinessError = message.toLowerCase().contains('absen') ||
                message.toLowerCase().contains('jam kerja') ||
                message.toLowerCase().contains('jadwal');

            if (!isBusinessError && context != null && context.mounted) {
              final isIdor = message.toLowerCase().contains('bukan transaksi') ||
                  message.toLowerCase().contains('tidak memiliki hak akses');
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Akses Ditolak'),
                  content: Text(isIdor ? 'Ini bukan transaksi Anda.' : (message.isNotEmpty ? message : 'Akses ditolak (403).')),
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
