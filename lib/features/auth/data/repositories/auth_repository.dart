import 'dart:convert';
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

  /// Login untuk Kandang.
  /// Memanggil POST /api/login/kandang.
  Future<Map<String, dynamic>> loginKandang(String kdgCode, String pin) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.loginKandang,
      data: {
        'kdg_code': kdgCode,
        'kdg_pin': pin,
      },
    );

    final token = response.data['access_token'] as String;
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'kandang_data', value: jsonEncode(response.data['kandang']));

    return {
      'token': token,
      'kandang': response.data['kandang'],
    };
  }

  /// Verifikasi Barcode Kandang dengan Geofencing.
  /// Memanggil POST /api/kandang/verify-barcode.
  Future<Map<String, dynamic>> verifyBarcode(String barcode, {double? latitude, double? longitude}) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.verifyBarcodeKandang,
      data: {
        'barcode': barcode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );

    return response.data['data'] as Map<String, dynamic>;
  }

  /// Login untuk Sales/Kurir.
  /// Memanggil POST /api/login/sales.
  Future<UserModel> loginSales(String loginname, String password) async {
    final response = await _dioClient.dio.post(
      ApiEndpoints.loginSales,
      data: {
        'usr_loginname': loginname,
        'usr_password': password,
      },
    );

    final token = response.data['access_token'] as String;
    await _storage.write(key: 'auth_token', value: token);

    return UserModel.fromJson(response.data['user']);
  }

  /// Logout dari Laravel API.
  Future<void> logout() async {
    try {
      await _dioClient.dio.post(ApiEndpoints.logout);
    } catch (_) {
    } finally {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'kandang_data');
    }
  }

  /// Mengecek apakah ada token tersimpan di HP.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  /// Mengambil data kandang yang tersimpan di storage.
  Future<Map<String, dynamic>?> getKandangData() async {
    final dataStr = await _storage.read(key: 'kandang_data');
    if (dataStr != null) {
      try {
        return jsonDecode(dataStr) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
