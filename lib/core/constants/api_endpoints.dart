/// Kumpulan endpoint API Laravel.
///
/// Semua path endpoint dikumpulkan di sini agar:
/// 1. Mudah ditemukan dan diubah.
/// 2. Tidak ada typo karena path ditulis satu kali.
/// 3. Konsisten di seluruh aplikasi.
///
/// Contoh penggunaan:
/// ```dart
/// final response = await dio.post(ApiEndpoints.login, data: {...});
/// ```
///
/// Base URL (misal: http://127.0.0.1:8000/api) sudah diatur
/// di DioClient, jadi di sini cukup tulis path-nya saja.
class ApiEndpoints {
  ApiEndpoints._();

  // === Autentikasi ===
  static const String loginSales = '/login/sales';
  static const String loginKandang = '/login/kandang';
  static const String verifyBarcodeKandang = '/kandang/verify-barcode';
  static const String logout = '/logout';
  static const String me = '/me'; // GET data user yang sedang login

  // === Versi & Update ===
  static const String checkVersion = '/check-update';
}
