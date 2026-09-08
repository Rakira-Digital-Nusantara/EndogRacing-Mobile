import 'package:flutter/material.dart';

import '../../kandang/data/models/kandang_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  UserModel? _user;
  KandangModel? _kandang;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  UserModel? get user => _user;
  KandangModel? get kandang => _kandang;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  Future<bool> loginKandang(String kdgCode, String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authRepository.loginKandang(kdgCode, pin);
      _kandang = KandangModel.fromJson(data['kandang']);
      _user = null; // Pastikan user kosong jika login sebagai kandang
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyBarcode(String barcode, {double? latitude, double? longitude}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authRepository.verifyBarcode(barcode, latitude: latitude, longitude: longitude);
      _isLoading = false;
      notifyListeners();
      return data;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return null;
    }
  }

  Future<bool> loginSales(String loginname, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.loginSales(loginname, password);
      _kandang = null; // Pastikan kandang kosong jika login sebagai sales
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> checkLoginStatus() async {
    final hasToken = await _authRepository.hasToken();
    if (hasToken) {
      // Restore kandang if any
      final kandangData = await _authRepository.getKandangData();
      if (kandangData != null) {
        _kandang = KandangModel.fromJson(kandangData);
      }
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
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
    if (error.toString().contains('401')) {
      return 'Kandang atau PIN salah (401).';
    }
    return 'Terjadi kesalahan: ${error.toString()}';
  }
}
