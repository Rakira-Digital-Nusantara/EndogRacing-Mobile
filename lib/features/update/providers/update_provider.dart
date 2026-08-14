import 'package:flutter/material.dart';

import '../../../core/utils/version_checker.dart';

/// UpdateProvider mengelola state pembaruan aplikasi.
///
/// Provider ini bertanggung jawab untuk:
/// 1. Mengecek apakah ada versi terbaru saat app dibuka.
/// 2. Menyimpan informasi update (changelog, URL, dll).
/// 3. Mengelola progress download APK.
class UpdateProvider extends ChangeNotifier {
  final VersionChecker _versionChecker;

  UpdateProvider(this._versionChecker);

  // === State ===
  UpdateInfo? _updateInfo; // Info update dari server
  bool _isDownloading = false; // Sedang mendownload APK?
  double _downloadProgress = 0.0; // Progress download (0.0 - 1.0)
  String? _errorMessage;

  // === Getter ===
  UpdateInfo? get updateInfo => _updateInfo;
  bool get hasUpdate => _updateInfo != null;
  bool get isForceUpdate => _updateInfo?.forceUpdate ?? false;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;

  /// Cek apakah ada update dari server Laravel.
  ///
  /// Dipanggil sekali saat app pertama kali dibuka.
  Future<void> checkForUpdate() async {
    _updateInfo = await _versionChecker.checkForUpdate();
    notifyListeners();
  }

  /// Download APK dan buka installer Android.
  Future<void> downloadUpdate() async {
    if (_updateInfo == null) return;

    _isDownloading = true;
    _downloadProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    try {
      await _versionChecker.downloadAndInstallApk(
        _updateInfo!.downloadUrl,
        onProgress: (received, total) {
          _downloadProgress = received / total;
          notifyListeners(); // Update progress bar di UI
        },
      );
      _isDownloading = false;
      notifyListeners();
    } catch (e) {
      _isDownloading = false;
      _errorMessage = 'Gagal mendownload update. Silakan coba lagi.';
      notifyListeners();
    }
  }

  /// Abaikan update (jika bukan force update).
  void dismissUpdate() {
    _updateInfo = null;
    notifyListeners();
  }
}
