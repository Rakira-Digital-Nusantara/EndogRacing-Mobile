import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// AuthRepository bertanggung jawab untuk semua komunikasi
/// dengan Laravel API yang berkaitan dengan autentikasi.
///
/// Repository ini memisahkan logika API dari UI,
/// sehingga kode lebih bersih dan mudah di-test.
///
/// Pola penggunaan:
/// ```dart
/// final repo = AuthRepository(dioClient);
/// final user = await repo.login('email@test.com', 'password123');
/// ```
class AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._dioClient);

  /// Login ke Laravel API.
  ///
  /// Mengirim email & password ke POST /api/login.
  /// Jika berhasil, token disimpan ke secure storage
  /// dan data user dikembalikan.
  ///
  /// Contoh response sukses dari Laravel:
  /// ```json
  /// {
  ///   "token": "1|abcdef123456...",
  ///   "user": { "id": 1, "name": "Ridho", "email": "ridho@test.com" }
  /// }
  /// ```
  Future<UserModel> login(String email, String password) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    // Simpan token ke secure storage (terenkripsi)
    final token = response.data['token'] as String;
    await _storage.write(key: 'auth_token', value: token);

    // Konversi JSON user ke UserModel
    return UserModel.fromJson(response.data['user']);
  }

  /// Ambil data user yang sedang login (GET /api/me).
  ///
  /// Digunakan saat app dibuka ulang untuk mengecek
  /// apakah token masih valid.
  Future<UserModel> getMe() async {
    final response = await _dioClient.dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data);
  }

  /// Logout dari Laravel API.
  ///
  /// Menghapus token dari server (POST /api/logout)
  /// dan dari secure storage di HP.
  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiEndpoints.logout);
    } catch (_) {
      // Abaikan error saat logout (misal: sudah expired)
    } finally {
      // Selalu hapus token lokal, apapun yang terjadi
      await _storage.delete(key: 'auth_token');
    }
  }

  /// Mengecek apakah ada token tersimpan di HP.
  /// Berguna untuk menentukan apakah user perlu login ulang.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }
}
