import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/dio_client.dart';

class SalesProvider with ChangeNotifier {
  final DioClient _dioClient;

  SalesProvider(this._dioClient);

  bool _isLoading = false;
  String _error = '';

  bool get isLoading => _isLoading;
  String get error => _error;

  // Master Data
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _salesHistory = [];
  double _stokGudang = 0.0;
  Map<String, dynamic>? _dashboardData;
  
  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get salesHistory => _salesHistory;
  double get stokGudang => _stokGudang;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  // --- API Integrations ---

  /// GET /api/penjualan/form
  Future<void> fetchPenjualanForm() async {
    _isLoading = true;
    _error = '';
    _customers.clear(); // Hapus data lama (dummy/cache)
    _products.clear();
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/penjualan/form');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          if (data.containsKey('customers') && data['customers'] is List) {
             _customers = (data['customers'] as List).map((e) => {
               'code': e['customer_code'],
               'name': e['customer_name'],
               'saldo': e['saldo_deposit'] ?? 0,
             }).toList();
          } else if (data.containsKey('list_customer') && data['list_customer'] is List) {
             _customers = (data['list_customer'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
          
          if (data.containsKey('products') && data['products'] is List) {
             _products = (data['products'] as List).map((e) => {
               'sku': e['sku_product'],
               'name': e['sku_name'],
               'hpp': e['harga_jual_final'] ?? e['harga_dasar_cogs'] ?? 20000,
             }).toList();
          } else if (data.containsKey('list_product') && data['list_product'] is List) {
             _products = (data['list_product'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch penjualan form: $e');
      _error = 'Gagal memuat data penjualan';
    } finally {
      // Emergency Dummy Data jika database backend benar-benar kosong
      if (_customers.isEmpty) {
        _customers = [
          {'code': 'CST-001', 'name': 'Toko Barokah (Dummy)', 'saldo': 1500000},
        ];
      }
      if (_products.isEmpty) {
        _products = [
          {'sku': 'TLR-001', 'name': 'Telur Utuh (Dummy)', 'hpp': 25000},
        ];
      }
      
      _isLoading = false;
      notifyListeners();
    }
  }

  /// POST /api/penjualan
  Future<bool> submitPenjualan(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/penjualan',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal menyimpan penjualan';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('errors')) {
             _error = data['errors'].toString();
          } else {
             _error = data['message'] ?? 'Terjadi kesalahan server: $data';
          }
        } else {
          _error = 'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
        }
      } else {
        _error = 'Kesalahan sistem: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /api/inventory/stok
  Future<void> fetchStokGudang() async {
    try {
      final response = await _dioClient.dio.get('/inventory/stok');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List && data.isNotEmpty) {
          // Asumsi item pertama adalah stok telur di gudang utama
          _stokGudang = double.tryParse(data.first['qty']?.toString() ?? '0') ?? 0.0;
        }
      }
    } catch (e) {
      debugPrint('Stok Gudang API failed: $e');
      _stokGudang = 450.0; // Dummy fallback
    }
    notifyListeners();
  }

  /// POST /api/sales/deposit-barang
  Future<bool> submitPenarikanBarang(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/sales/deposit-barang',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal menarik barang';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('errors')) {
             _error = data['errors'].toString();
          } else {
             _error = data['message'] ?? 'Terjadi kesalahan server: $data';
          }
        } else {
          _error = 'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
        }
      } else {
        _error = 'Kesalahan sistem: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /api/deposit/{customer_code}/saldo
  Future<double> checkDepositSaldo(String customerCode) async {
    try {
      final response = await _dioClient.dio.get('/deposit/$customerCode/saldo');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data['saldo'] != null) {
           return double.tryParse(data['saldo'].toString()) ?? 0.0;
        }
      }
    } catch (e) {
      debugPrint('Check deposit saldo failed: $e');
    }
    // Dummy fallback based on code
    if (customerCode == 'CST-001') return 1500000.0;
    if (customerCode == 'CST-002') return 500000.0;
    return 0.0;
  }

  /// GET /api/deposit/{customer_code}/riwayat
  Future<List<Map<String, dynamic>>> checkDepositRiwayat(String customerCode) async {
    try {
      final response = await _dioClient.dio.get('/deposit/$customerCode/riwayat');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
           return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Check deposit riwayat failed: $e');
    }
    // Dummy fallback
    return [
      {'tanggal': '2026-08-28', 'jenis': 'IN', 'nominal': 1000000, 'ket': 'Top Up Tunai ke Sales'},
      {'tanggal': '2026-08-29', 'jenis': 'OUT', 'nominal': 250000, 'ket': 'Pembelian Telur'},
    ];
  }

  /// POST /api/deposit/topup
  Future<bool> submitTopUpDeposit(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/deposit/topup',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal memproses setoran deposit';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('errors')) {
             _error = data['errors'].toString();
          } else {
             _error = data['message'] ?? 'Terjadi kesalahan server: $data';
          }
        } else {
          _error = 'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
        }
      } else {
        _error = 'Kesalahan sistem: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /api/penjualan
  Future<void> fetchSalesHistory() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/penjualan');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          _salesHistory = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (data is Map && data.containsKey('data')) { // Handle pagination if any
          _salesHistory = (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch sales history: $e');
      _error = 'Gagal memuat histori penjualan';
      // Fallback
      if (_salesHistory.isEmpty) {
        _salesHistory = getDummySalesHistory();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// POST /api/penjualan/bayar-piutang
  Future<bool> submitTerimaCicilan(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/penjualan/bayar-piutang',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal menerima cicilan';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('errors')) {
             _error = data['errors'].toString();
          } else {
             _error = data['message'] ?? 'Terjadi kesalahan server: $data';
          }
        } else {
          _error = 'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
        }
      } else {
        _error = 'Kesalahan sistem: ${e.toString()}';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- DASHBOARD API ---
  Future<void> fetchSalesDashboard({String? tanggal}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (tanggal != null && tanggal.isNotEmpty) {
        queryParams['tanggal'] = tanggal;
      }

      final response = await _dioClient.dio.get('/sales/dashboard', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
           _dashboardData = Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch sales dashboard: $e');
      _error = 'Gagal memuat dashboard penjualan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- DUMMY DATA / FALLBACKS ---

  Map<String, dynamic> getDashboardSummary() {
    if (_dashboardData != null) {
       final lunas = double.tryParse(_dashboardData!['tagihan_lunas']?.toString() ?? '0') ?? 0;
       final belum = double.tryParse(_dashboardData!['tagihan_belum_lunas']?.toString() ?? '0') ?? 0;
       return {
         'total_penjualan': lunas + belum,
         'terbayar': lunas,
         'belum_bayar': belum,
       };
    }

    double totalPenjualan = 0;
    double terbayar = 0;
    double belumBayar = 0;

    for (var trx in _salesHistory) {
      double total = double.tryParse(trx['total']?.toString() ?? '0') ?? 0;
      double dibayar = double.tryParse(trx['dibayar']?.toString() ?? '0') ?? 0;
      double kurang = double.tryParse(trx['kurang']?.toString() ?? '0') ?? 0;
      
      totalPenjualan += total;
      terbayar += dibayar;
      belumBayar += kurang;
    }

    return {
      'total_penjualan': totalPenjualan,
      'terbayar': terbayar,
      'belum_bayar': belumBayar,
    };
  }

  List<Map<String, dynamic>> getDummySalesHistory() {
    return [
      {
        'id': 'TRX-20231024-001',
        'customer_name': 'Bpk. Ahmad Subarjo',
        'tanggal': '24 Okt',
        'status': 'LUNAS',
        'total': 4500000.0,
        'dibayar': 4500000.0,
        'kurang': 0.0,
      },
      {
        'id': 'TRX-20231024-002',
        'customer_name': 'Toko Kurnia Makmur',
        'tanggal': '24 Okt',
        'status': 'PIUTANG',
        'total': 12800000.0,
        'dibayar': 10000000.0,
        'kurang': 2800000.0,
      },
      {
        'id': 'TRX-20231022-005',
        'customer_name': 'PT. Sentosa',
        'tanggal': '22 Okt',
        'status': 'RETUR',
        'total': -500000.0,
        'dibayar': 0.0,
        'kurang': 0.0,
        'catatan': '2 Tray Telur Pecah',
      },
    ];
  }
}
