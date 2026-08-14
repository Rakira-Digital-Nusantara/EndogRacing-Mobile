import 'package:flutter/material.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

/// AuthProvider mengelola "status autentikasi" di seluruh aplikasi.
///
/// Provider ini menyimpan:
/// - Apakah user sedang login atau belum.
/// - Data user yang sedang login.
/// - Status loading saat proses login.
/// - Pesan error jika login gagal.
///
/// Cara kerja Provider di Flutter:
/// Ketika data di dalam class ini berubah (misal: user berhasil login),
/// Provider akan memberitahu semua widget yang "mendengarkan" (listen)
/// agar widget tersebut bisa memperbarui tampilan secara otomatis.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  // === State (Data yang disimpan) ===

  UserModel? _user; // Data user yang sedang login
  bool _isLoading = false; // Apakah sedang proses (login/logout)
  bool _isLoggedIn = false; // Apakah user sudah login
  String? _errorMessage; // Pesan error terakhir

  // === Getter (Cara widget membaca data) ===

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  /// Melakukan login.
  ///
  /// Dipanggil dari LoginScreen saat user menekan tombol "Login".
  /// Setelah berhasil, [isLoggedIn] akan menjadi `true`
  /// dan GoRouter akan otomatis mengarahkan ke halaman Home.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Beritahu UI: "Sedang loading..."

    try {
      _user = await _authRepository.login(email, password);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners(); // Beritahu UI: "Login berhasil!"
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners(); // Beritahu UI: "Login gagal!"
      return false;
    }
  }

  /// Mengecek apakah user masih login saat app dibuka ulang.
  ///
  /// Dipanggil sekali saat app pertama kali dibuka.
  /// Jika ada token tersimpan, coba ambil data user dari server.
  Future<void> checkLoginStatus() async {
    final hasToken = await _authRepository.hasToken();
    if (hasToken) {
      try {
        _user = await _authRepository.getMe();
        _isLoggedIn = true;
      } catch (_) {
        // Token expired atau tidak valid → hapus dan anggap belum login
        _isLoggedIn = false;
      }
    }
    notifyListeners();
  }

  /// Melakukan logout.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authRepository.logout();

    _user = null;
    _isLoggedIn = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners(); // Beritahu UI: "User sudah logout."
  }

  /// Menghapus pesan error (misal: setelah user menutup snackbar).
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Mengubah error dari Dio/Exception menjadi pesan yang ramah pengguna.
  String _parseError(dynamic error) {
    if (error.toString().contains('422')) {
      return 'Email atau password salah.';
    }
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
