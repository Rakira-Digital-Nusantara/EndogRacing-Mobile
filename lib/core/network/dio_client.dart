import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient() {
    dio = Dio(
      BaseOptions(
        // Base URL diambil dari file .env
        baseUrl: dotenv.env['API_URL'] ?? 'http://127.0.0.1:8000/api',
        // Timeout: jika server tidak merespons dalam 30 detik, batalkan.
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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
          }
          handler.next(options); // Lanjutkan request
        },

        // --- SAAT MENERIMA RESPONSE ---
        onResponse: (response, handler) {
          handler.next(response); // Lanjutkan response seperti biasa
        },

        // --- SAAT TERJADI ERROR ---
        onError: (DioException error, handler) {
          // Jika server mengembalikan 401 (Unauthorized),
          // artinya token sudah expired atau tidak valid.
          // Anda bisa menambahkan logika auto-logout di sini nanti.
          if (error.response?.statusCode == 401) {
            // TODO: Tambahkan logika logout otomatis di sini
            // Contoh: hapus token, arahkan ke halaman login
          }
          handler.next(error); // Teruskan error ke pemanggil
        },
      ),
    );
  }
}
