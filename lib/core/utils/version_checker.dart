import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../network/dio_client.dart';
import '../constants/api_endpoints.dart';

/// VersionChecker bertanggung jawab untuk:
/// 1. Mengecek apakah ada versi aplikasi terbaru di server Laravel.
/// 2. Mendownload file APK dari server.
/// 3. Membuka file APK agar pengguna bisa menginstall update.
///
/// Alur kerja:
/// ```
/// App dibuka → checkForUpdate() → Bandingkan versi
///   → Jika ada update → return UpdateInfo (berisi URL, changelog, dll)
///   → Jika tidak ada  → return null
/// ```
class VersionChecker {
  final DioClient _dioClient;

  VersionChecker(this._dioClient);

  /// Mengecek apakah ada versi terbaru di server Laravel.
  ///
  /// Mengembalikan [UpdateInfo] jika ada update, atau `null` jika sudah versi terbaru.
  ///
  /// Endpoint Laravel yang dipanggil: GET /api/check-version
  /// Response yang diharapkan dari Laravel:
  /// ```json
  /// {
  ///   "latest_version": "1.2.0",
  ///   "download_url": "https://server.com/releases/app-v1.2.0.apk",
  ///   "force_update": true,
  ///   "changelog": "Perbaikan bug login."
  /// }
  /// ```
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Ambil versi_code app yang sedang terinstall di HP pengguna (buildNumber)
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Tanya ke server Laravel: versi_code terbaru berapa?
      final response = await _dioClient.dio.get(ApiEndpoints.checkVersion);

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersionCode = data['version_code'] is int ? data['version_code'] : int.tryParse(data['version_code'].toString()) ?? 0;

        // Bandingkan versi_code saat ini dengan versi_code terbaru
        if (latestVersionCode > currentVersionCode) {
          final force = data['is_force_update'] == 1 || data['is_force_update'] == true || data['is_force_update'] == '1';
          return UpdateInfo(
            latestVersion: latestVersionCode.toString(),
            downloadUrl: data['download_url'] as String? ?? '',
            forceUpdate: force,
            changelog: data['description'] as String? ?? '',
          );
        }
      }
      return null; // Tidak ada update
    } catch (e) {
      // Jika gagal cek (misal: tidak ada internet), abaikan saja.
      // Jangan sampai error ini membuat app crash.
      return null;
    }
  }



  /// Mendownload file APK dari [url] dan membuka installer Android.
  ///
  /// Alur:
  /// 1. Minta izin penyimpanan.
  /// 2. Download APK ke folder Download.
  /// 3. Buka file APK → Android menampilkan layar instalasi.
  ///
  /// [onProgress] adalah callback untuk menampilkan progress download
  /// (misal: 45% → tampilkan progress bar di UI).
  Future<void> downloadAndInstallApk(
    String url, {
    Function(int received, int total)? onProgress,
  }) async {
    // Minta izin untuk menginstall dari sumber tidak dikenal
    final installStatus = await Permission.requestInstallPackages.request();
    if (!installStatus.isGranted) {
      throw Exception(
        'Izin instalasi dari sumber tidak dikenal belum diberikan.',
      );
    }

    // Tentukan lokasi penyimpanan file APK
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/app_update.apk';

    // Download APK dari server
    await _dioClient.dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (onProgress != null && total != -1) {
          onProgress(received, total);
        }
      },
    );

    // Buka file APK → Android akan menampilkan layar instalasi
    await OpenFilex.open(filePath);
  }
}

/// Data class yang menyimpan informasi update dari server.
class UpdateInfo {
  final String latestVersion;
  final String downloadUrl;
  final bool forceUpdate;
  final String changelog;

  UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.forceUpdate,
    required this.changelog,
  });
}
