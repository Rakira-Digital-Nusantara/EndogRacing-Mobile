import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';

class DashboardProvider extends ChangeNotifier {
  final DioClient _dioClient;
  DashboardProvider(this._dioClient);

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String _filter = 'harian';
  String get filter => _filter;
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  List<Map<String, dynamic>> _aktivitasHarian = [];
  List<Map<String, dynamic>> get aktivitasHarian => _aktivitasHarian;
  bool _isLoadingAktivitas = false;
  bool get isLoadingAktivitas => _isLoadingAktivitas;

  // --- Formatters for UI ---
  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
    if (value is double) {
      if (value == value.truncateToDouble()) {
        return value.truncate().toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.');
      }
      // Format double, e.g. 125.5 -> 125,5
      String str = value.toStringAsFixed(1).replaceAll('.', ',');
      // Add thousands separator if needed
      return str; 
    }
    return value.toString();
  }

  String get pakanTerpakai => _dashboardData == null ? '-' : _formatNumber(_dashboardData!['metrik']['pakan_terpakai_kg']);
  
  String get telurProduksiKas {
    if (_dashboardData == null) return '-';
    final metrik = _dashboardData!['metrik'];
    if (metrik['telur_hari_ini_kas'] != null) return _formatNumber(metrik['telur_hari_ini_kas']);
    final kg = metrik['telur_hari_ini_kg'];
    if (kg == null) return '0';
    double val = (kg is int) ? kg.toDouble() : (kg as double);
    return _formatNumber((val / 15.0).floor());
  }
  
  String get telurProduksiKg => _dashboardData == null ? '-' : '${_formatNumber(_dashboardData!['metrik']['telur_hari_ini_kg'])} kg';
  
  String get telurRusakKas {
    if (_dashboardData == null) return '-';
    final metrik = _dashboardData!['metrik'];
    if (metrik['telur_rusak_kas'] != null) return _formatNumber(metrik['telur_rusak_kas']);
    final kg = metrik['telur_rusak_kg'];
    if (kg == null) return '0';
    double val = (kg is int) ? kg.toDouble() : (kg as double);
    return _formatNumber((val / 15.0).floor());
  }
  
  String get telurRusakKg => _dashboardData == null ? '-' : '${_formatNumber(_dashboardData!['metrik']['telur_rusak_kg'])} kg';
  
  String get kematian => _dashboardData == null ? '-' : _formatNumber(_dashboardData!['metrik']['kematian_ekor']);
  String get totalPopulasi => _dashboardData == null ? '-' : _formatNumber(_dashboardData!['metrik']['total_populasi_ekor']);
  String get sisaStokPakan => _dashboardData == null ? '-' : _formatNumber(_dashboardData!['metrik']['sisa_stok_pakan_kg']);

  bool get isAbsenMasukDone => _dashboardData?['aktivitas']?['is_absen_masuk_done'] ?? false;
  bool get isAbsenPulangDone => _dashboardData?['aktivitas']?['is_absen_pulang_done'] ?? false;
  bool get isPakanHarianDone => _dashboardData?['aktivitas']?['is_pakan_harian_done'] ?? false;
  bool get isProduksiTelurDone => _dashboardData?['aktivitas']?['is_produksi_telur_done'] ?? false;

  String get checklistProgress {
    if (_dashboardData == null || _dashboardData!['aktivitas'] == null) return '0/0 SELESAI';
    final aktivitas = _dashboardData!['aktivitas'];
    final done = aktivitas['checklist_rutin_done'] ?? aktivitas['ceklist_rutin_done'] ?? 0;
    final total = aktivitas['checklist_rutin_total'] ?? aktivitas['ceklist_rutin_total'] ?? 0;
    return '$done/$total SELESAI';
  }

  double get checklistPercentage {
    if (_dashboardData == null || _dashboardData!['aktivitas'] == null) return 0.0;
    final aktivitas = _dashboardData!['aktivitas'];
    int total = aktivitas['checklist_rutin_total'] ?? aktivitas['ceklist_rutin_total'] ?? 0;
    int done = aktivitas['checklist_rutin_done'] ?? aktivitas['ceklist_rutin_done'] ?? 0;
    return total > 0 ? (done / total) : 0.0;
  }

  Future<void> fetchDashboardData(String kdgCode, {String? newFilter, String? startDate, String? endDate}) async {
    if (newFilter != null) {
      _filter = newFilter.toLowerCase();
    }
    _isLoading = true;
    notifyListeners();
    try {
      _errorMessage = '';
      debugPrint('Fetching dashboard data for filter: $_filter');
      final queryParams = <String, dynamic>{
        'filter': _filter,
      };
      if (startDate != null && endDate != null) {
        queryParams['start_date'] = startDate;
        queryParams['end_date'] = endDate;
      }
      
      final response = await _dioClient.dio.get('/kandang/dashboard', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data['data'] != null) {
        _dashboardData = response.data['data'];
      } else {
        _errorMessage = 'Invalid response format: ${response.data}';
        debugPrint('Dashboard Error: $_errorMessage');
      }
    } on DioException catch (e) {
      _errorMessage = 'Dio Error (${e.response?.statusCode}): ${e.response?.data ?? e.message}';
      debugPrint('Dashboard DioException: $_errorMessage');
    } catch (e) {
      _errorMessage = 'Generic Error: $e';
      debugPrint('Dashboard Generic Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String kdgCode, String filterValue) {
    if (_filter != filterValue.toLowerCase()) {
      fetchDashboardData(kdgCode, newFilter: filterValue.toLowerCase());
    }
  }

  Future<void> fetchAktivitasHarian(String tanggal) async {
    _isLoadingAktivitas = true;
    notifyListeners();
    try {
      final response = await _dioClient.dio.get('/kandang/aktivitas-harian', queryParameters: {'tanggal': tanggal});
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        _aktivitasHarian = data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        _aktivitasHarian = [];
      }
    } catch (e) {
      debugPrint('Error fetchAktivitasHarian: $e');
      _aktivitasHarian = [];
    } finally {
      _isLoadingAktivitas = false;
      notifyListeners();
    }
  }
}
