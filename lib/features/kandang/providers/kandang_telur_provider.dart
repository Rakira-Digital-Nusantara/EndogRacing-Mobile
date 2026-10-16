import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../data/models/produksi_telur_model.dart';
import '../data/models/setor_telur_model.dart';
import '../data/repositories/kandang_telur_repository.dart';

class KandangTelurProvider extends ChangeNotifier {
  final KandangTelurRepository _repository;

  KandangTelurProvider(this._repository);

  // --- Saldo Telur Kandang State ---
  List<SaldoTelurKandangItem> _saldoTelurList = [];
  List<SaldoTelurKandangItem> get saldoTelurList => _saldoTelurList;

  bool _isLoadingSaldo = false;
  bool get isLoadingSaldo => _isLoadingSaldo;

  String _errorSaldo = '';
  String get errorSaldo => _errorSaldo;

  // Helper getters for summary
  double get totalSaldoKg => _saldoTelurList.fold(0.0, (sum, item) => sum + item.saldoKg);
  int get totalKasSiapSetor => _saldoTelurList.fold(0, (sum, item) => sum + item.kasTersedia);
  double get totalSisaKg => _saldoTelurList.fold(0.0, (sum, item) => sum + item.sisaKg);

  Future<void> fetchSaldoKandang(String kdgCode) async {
    _isLoadingSaldo = true;
    _errorSaldo = '';
    notifyListeners();

    try {
      _saldoTelurList = await _repository.getSaldoTelurKandang(kdgCode);
    } catch (e) {
      if (e is DioException) {
        _errorSaldo = e.response?.data?['message']?.toString() ?? e.message ?? 'Gagal memuat saldo kandang';
      } else {
        _errorSaldo = e.toString();
      }
    } finally {
      _isLoadingSaldo = false;
      notifyListeners();
    }
  }

  // --- Riwayat Setor State ---
  List<RiwayatSetorItem> _riwayatSetorList = [];
  List<RiwayatSetorItem> get riwayatSetorList => _riwayatSetorList;

  bool _isLoadingRiwayat = false;
  bool get isLoadingRiwayat => _isLoadingRiwayat;

  String _errorRiwayat = '';
  String get errorRiwayat => _errorRiwayat;

  Future<void> fetchRiwayatSetor(String kdgCode, {String? startDate, String? endDate}) async {
    _isLoadingRiwayat = true;
    _errorRiwayat = '';
    notifyListeners();

    try {
      _riwayatSetorList = await _repository.getRiwayatSetorTelur(
        kdgCode: kdgCode,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      if (e is DioException) {
        _errorRiwayat = e.response?.data?['message']?.toString() ?? e.message ?? 'Gagal memuat riwayat';
      } else {
        _errorRiwayat = e.toString();
      }
    } finally {
      _isLoadingRiwayat = false;
      notifyListeners();
    }
  }

  // --- Dashboard Setor State (Khusus Ringkasan Metrik Dashboard) ---
  List<RiwayatSetorItem> _dashboardSetorList = [];
  List<RiwayatSetorItem> get dashboardSetorList => _dashboardSetorList;

  bool _isLoadingDashboardSetor = false;
  bool get isLoadingDashboardSetor => _isLoadingDashboardSetor;

  int get totalDashboardSetorKas => _dashboardSetorList.fold(0, (sum, item) => sum + item.totalKas);
  double get totalDashboardSetorKg => _dashboardSetorList.fold(0.0, (sum, item) => sum + item.totalKg);

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
    if (value is double) {
      if (value == value.truncateToDouble()) {
        return value.truncate().toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
      }
      return value.toStringAsFixed(1).replaceAll('.', ',');
    }
    return value.toString();
  }

  String get formatDashboardSetorKg => _formatNumber(totalDashboardSetorKg);
  String get formatDashboardSetorKas => _formatNumber(totalDashboardSetorKas);

  Future<void> fetchDashboardSetor(String kdgCode, {String? startDate, String? endDate}) async {
    _isLoadingDashboardSetor = true;
    notifyListeners();

    try {
      _dashboardSetorList = await _repository.getRiwayatSetorTelur(
        kdgCode: kdgCode,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error fetchDashboardSetor: $e');
      _dashboardSetorList = [];
    } finally {
      _isLoadingDashboardSetor = false;
      notifyListeners();
    }
  }
}

