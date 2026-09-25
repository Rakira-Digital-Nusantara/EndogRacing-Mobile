import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../data/models/absensi_model.dart';
import '../data/repositories/absensi_repository.dart';

class AbsensiProvider extends ChangeNotifier {
  final AbsensiRepository _repository;

  AbsensiProvider(this._repository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AbsensiModel> _history = [];
  List<AbsensiModel> get history => _history;

  bool get isSudahAbsenMasukHariIni {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayStrReversed = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    return _history.any((e) => (e.tanggalAbsen.startsWith(todayStr) || e.tanggalAbsen.startsWith(todayStrReversed)) && e.tipeAbsen.trim().toLowerCase() == 'masuk');
  }

  bool get isSudahAbsenPulangHariIni {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayStrReversed = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    return _history.any((e) => (e.tanggalAbsen.startsWith(todayStr) || e.tanggalAbsen.startsWith(todayStrReversed)) && e.tipeAbsen.trim().toLowerCase() == 'pulang');
  }

  Future<void> checkHistoryHariIni() async {
    if (_history.isEmpty) {
      await fetchHistory();
    }
  }

  // Mendapatkan tipe absen berikutnya ("Masuk" atau "Pulang")
  // Logika sederhana: jika history hari ini ganjil (hanya ada Masuk), maka Pulang.
  // Jika genap (Kosong atau sudah Masuk & Pulang), maka Masuk.
  String get nextAbsenType {
    if (_history.isEmpty) return 'Masuk';
    
    // Asumsi history diurutkan dari terbaru ke terlama
    // Cari absen hari ini
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayStrReversed = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    
    final historyToday = _history.where((element) {
      if (element.tanggalAbsen.isEmpty) return false;
      return element.tanggalAbsen.startsWith(todayStr) || element.tanggalAbsen.startsWith(todayStrReversed);
    }).toList();

    if (historyToday.isEmpty) return 'Masuk';
    
    // Jika ada Masuk tapi belum ada Pulang
    bool hasMasuk = historyToday.any((e) => e.tipeAbsen.trim().toLowerCase() == 'masuk');
    bool hasPulang = historyToday.any((e) => e.tipeAbsen.trim().toLowerCase() == 'pulang');

    if (hasMasuk && !hasPulang) return 'Pulang';
    
    // Default kembali ke Masuk (misal besoknya)
    return 'Masuk';
  }

  bool _isSales = false;

  void setRole(bool isSales) {
    _isSales = isSales;
  }

  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _repository.getAbsensiHistory(isSales: _isSales);
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitAbsensi({
    required String photoPath,
    required double latitude,
    required double longitude,
    String? forcedTipeAbsen,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tipe = forcedTipeAbsen ?? nextAbsenType;

      // Validasi jam sesuai aturan API (tapi menggunakan jam lokal HP agar akurat)
      final now = DateTime.now();
      final currentHour = now.hour;

      if (tipe.toLowerCase() == 'masuk') {
        if (currentHour < 6) {
          _errorMessage = "Gagal, belum waktunya masuk. Jam masuk minimal adalah 06:00";
          _isLoading = false;
          notifyListeners();
          return false;
        } else if (currentHour >= 16) {
          _errorMessage = "Gagal, batas waktu absen masuk sudah lewat (Maksimal 15:59).";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (tipe.toLowerCase() == 'pulang') {
        if (currentHour < 16) {
          _errorMessage = "Gagal, belum waktunya pulang. Jam pulang minimal adalah 16:00";
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      await _repository.submitAbsensi(
        tipeAbsen: tipe,
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
        isSales: _isSales,
      );
      
      // Refresh history setelah sukses
      await fetchHistory();
      return true;
    } on DioException catch (e) {
      _errorMessage = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  String _parseError(DioException error) {
    if (error.response?.data != null && error.response?.data['message'] != null) {
      return error.response?.data['message'];
    }
    return 'Terjadi kesalahan pada server.';
  }
}
