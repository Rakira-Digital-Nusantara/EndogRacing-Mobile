import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
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
  double _saldoBelumDisetor = 0.0;
  double _totalDiterima = 0.0;
  double _totalDisetor = 0.0;
  String? _gudangCode;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _rekapHarianData;
  Map<String, dynamic>? _rekapBulananData;
  Map<String, dynamic>? _riwayatSetoranData;
  List<Map<String, dynamic>> _riwayatStokMobil = [];
  Map<String, dynamic>? _salesProfile;

  // Ambil Barang Form State
  List<Map<String, dynamic>> _tarikGudangAsalList = [];
  Map<String, dynamic>? _tarikGudangTujuan;
  List<Map<String, dynamic>> _tarikProdukList = [];

  // Retur Form State
  Map<String, dynamic>? _returGudangTujuan;
  List<String> _returAlasanList = [];
  List<Map<String, dynamic>> _returProdukList = [];

  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get salesHistory => _salesHistory;
  double get stokGudang => _stokGudang;
  double get saldoBelumDisetor => _saldoBelumDisetor;
  double get totalDiterima => _totalDiterima;
  double get totalDisetor => _totalDisetor;
  String? get gudangCode => _gudangCode;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get rekapHarianData => _rekapHarianData;
  Map<String, dynamic>? get rekapBulananData => _rekapBulananData;
  Map<String, dynamic>? get riwayatSetoranData => _riwayatSetoranData;
  List<Map<String, dynamic>> get riwayatStokMobil => _riwayatStokMobil;
  Map<String, dynamic>? get salesProfile => _salesProfile;

  List<Map<String, dynamic>> get tarikGudangAsalList => _tarikGudangAsalList;
  Map<String, dynamic>? get tarikGudangTujuan => _tarikGudangTujuan;
  List<Map<String, dynamic>> get tarikProdukList => _tarikProdukList;

  Map<String, dynamic>? get returGudangTujuan => _returGudangTujuan;
  List<String> get returAlasanList => _returAlasanList;
  List<Map<String, dynamic>> get returProdukList => _returProdukList;

  // --- API Integrations ---

  /// GET /api/penjualan/form
  Future<void> fetchPenjualanForm() async {
    _isLoading = true;
    _error = '';
    _customers.clear(); // Hapus data lama (dummy/cache)
    _products.clear();
    notifyListeners();

    try {
      final response = await _dioClient.dio.get(
        '/penjualan/form',
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch},
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          if (data.containsKey('customers') && data['customers'] is List) {
            _customers = (data['customers'] as List)
                .map(
                  (e) => {
                    'code': e['customer_code'],
                    'name': e['customer_name'],
                    'saldo': e['saldo_deposit'] ?? 0,
                  },
                )
                .toList();
          } else if (data.containsKey('list_customer') &&
              data['list_customer'] is List) {
            _customers = (data['list_customer'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }

          if (data.containsKey('products') && data['products'] is List) {
            _products = (data['products'] as List)
                .map(
                  (e) => {
                    'sku': e['sku_product'],
                    'name': e['sku_name'],
                    'uom': e['sku_uom'],
                    'hpp': e['harga_jual_final'] ?? e['harga_dasar_cogs'] ?? 0,
                    'stok': e['stock_tersedia'] ?? 0,
                  },
                )
                .toList();
          } else if (data.containsKey('list_product') &&
              data['list_product'] is List) {
            _products = (data['list_product'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }

          if (data.containsKey('gudang_telur_code')) {
            _gudangCode = data['gudang_telur_code']?.toString();
          } else if (data.containsKey('gudang_code')) {
            _gudangCode = data['gudang_code']?.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch penjualan form: $e');
      _error = 'Gagal memuat data penjualan';
    } finally {
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
      final response = await _dioClient.dio.post('/penjualan', data: payload);
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
            _error = data['message']?.toString() ?? 'Terjadi kesalahan server';
            final Map<String, dynamic> extraData = Map.from(data)..remove('message')..remove('exception');
            if (extraData.isNotEmpty) {
              _error += '\nDetail: $extraData';
            }
          }
        } else {
          _error =
              'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
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

  /// POST /api/sales/ubah-wujud
  Future<bool> submitLaporPecahMobil(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post('/sales/ubah-wujud', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal melaporkan telur pecah';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            _error = data['message'].toString();
          } else {
            _error = 'Gagal melaporkan telur pecah';
          }
        } else {
          _error = 'Terjadi kesalahan jaringan (${e.response?.statusCode ?? "Unknown"})';
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

  /// POST /api/sales/retur-tukar
  Future<bool> submitReturTukar(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post('/sales/retur-tukar', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal mencatat retur tukar';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            _error = data['message'].toString();
          } else {
            _error = 'Gagal mencatat retur tukar';
          }
        } else {
          _error = 'Terjadi kesalahan jaringan (${e.response?.statusCode ?? "Unknown"})';
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

  /// GET /api/sales/stok-mobil
  Future<void> fetchStokMobil() async {
    try {
      final response = await _dioClient.dio.get('/sales/stok-mobil');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List && data.isNotEmpty) {
          double totalStokTelur = 0;
          for (var item in data) {
            final category = item['sku_category']?.toString() ?? '';
            // Sales hanya memantau stok telur (Produk)
            if (category == 'Produk' ||
                category.isEmpty ||
                category.toLowerCase() == 'telur') {
              totalStokTelur +=
                  double.tryParse(
                    item['stock_akhir']?.toString() ??
                        item['stock_tersedia']?.toString() ??
                        '0',
                  ) ??
                  0.0;
            }
          }
          _stokGudang = totalStokTelur;
        } else {
          _stokGudang = 0;
        }
      }
    } catch (e) {
      debugPrint('Stok Mobil API failed: $e');
      _stokGudang = 0;
    }
    notifyListeners();
  }

  /// GET /api/sales/tarik-barang/form
  Future<void> fetchTarikBarangForm() async {
    _isLoading = true;
    _error = '';
    _tarikGudangAsalList.clear();
    _tarikGudangTujuan = null;
    _tarikProdukList.clear();
    notifyListeners();

    try {
      final response = await _dioClient.dio.get(
        '/sales/tarik-barang/form?gudang_asal=GDG0001',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          if (data['gudang_asal'] is List) {
            _tarikGudangAsalList = List<Map<String, dynamic>>.from(
              data['gudang_asal'],
            );
          }
          if (data['gudang_tujuan'] is Map) {
            _tarikGudangTujuan = Map<String, dynamic>.from(
              data['gudang_tujuan'],
            );
          }
          if (data['produk'] is List) {
            _tarikProdukList = List<Map<String, dynamic>>.from(data['produk']);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch Tarik Barang Form: $e');
      _error = 'Gagal memuat form ambil barang';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /api/sales/retur/form
  Future<void> fetchReturForm() async {
    _isLoading = true;
    _error = '';
    _returGudangTujuan = null;
    _returAlasanList.clear();
    _returProdukList.clear();
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/sales/retur/form');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          if (data['gudang_tujuan'] is Map) {
            _returGudangTujuan = Map<String, dynamic>.from(
              data['gudang_tujuan'],
            );
          }
          if (data['alasan_retur'] is List) {
            _returAlasanList = List<String>.from(data['alasan_retur']);
          }
          if (data['produk'] is List) {
            _returProdukList = List<Map<String, dynamic>>.from(data['produk']);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch Retur Form: $e');
      _error = 'Gagal memuat form retur';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// POST /api/sales/deposit-barang
  Future<Map<String, dynamic>?> submitPenarikanBarang(
    Map<String, dynamic> payload,
  ) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/sales/deposit-barang',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : {'data': response.data};
      }
      _error = response.data['message'] ?? 'Gagal menarik barang';
      return null;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          _error = e.response?.data['message'] ?? 'Terjadi kesalahan';
        } else {
          _error = e.message ?? 'Terjadi kesalahan';
        }
      } else {
        _error = 'Kesalahan sistem: ${e.toString()}';
      }
      return null;
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
  Future<List<Map<String, dynamic>>> checkDepositRiwayat(
    String customerCode,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        '/deposit/$customerCode/riwayat',
      );
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
      {
        'tanggal': '2026-08-28',
        'jenis': 'IN',
        'nominal': 1000000,
        'ket': 'Top Up Tunai ke Sales',
      },
      {
        'tanggal': '2026-08-29',
        'jenis': 'OUT',
        'nominal': 250000,
        'ket': 'Pembelian Telur',
      },
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
          _error =
              'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
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

  /// GET /api/sales/saldo
  Future<void> fetchSaldoBelumDisetor() async {
    try {
      final response = await _dioClient.dio.get('/sales/saldo');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          _saldoBelumDisetor =
              double.tryParse(
                data['saldo_di_tangan']?.toString() ??
                    data['saldo_belum_disetor']?.toString() ??
                    '0',
              ) ??
              0.0;
          _totalDiterima =
              double.tryParse(data['total_diterima']?.toString() ?? '0') ?? 0.0;
          _totalDisetor =
              double.tryParse(data['total_disetor']?.toString() ?? '0') ?? 0.0;
        } else if (data is num) {
          _saldoBelumDisetor = data.toDouble();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch saldo di tangan: $e');
    }
    notifyListeners();
  }

  /// POST /api/sales/setor
  Future<bool> submitSetorKasBesar(FormData formData) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/sales/setor',
        data: formData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal memproses setoran kas besar';
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
          _error =
              'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
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

  /// POST /api/sales/setor-customer
  Future<bool> submitSetorPerCustomer(FormData formData) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post(
        '/sales/setor-customer',
        data: formData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal memproses setoran customer';
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
          _error =
              'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
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
  Future<void> fetchSalesHistory({
    String? statusBayar,
    String? search,
    String? customerCode,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{'page': page};
      if (statusBayar != null && statusBayar.isNotEmpty) {
        queryParams['status_bayar'] = statusBayar;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (customerCode != null && customerCode.isNotEmpty) {
        queryParams['customer_code'] = customerCode;
      }

      final response = await _dioClient.dio.get(
        '/penjualan',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          _salesHistory = data
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else if (data is Map && data.containsKey('data')) {
          // Handle pagination if any
          _salesHistory = (data['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch sales history: $e');
      _error = 'Gagal memuat histori penjualan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ambil detail transaksi (Eager load: customer, details, details.product)
  Future<Map<String, dynamic>?> fetchTransactionDetail(String jualCode) async {
    try {
      final encodedCode = Uri.encodeComponent(jualCode);
      // Constructing Uri directly to prevent Dio from double encoding the path
      final uri = Uri.parse('${DioClient.baseUrl}/admin-penjualan-sales/$encodedCode');
      final response = await _dioClient.dio.getUri(uri);
      
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching transaction detail: $e');
      if (e is DioException) {
        debugPrint('DioException details: ${e.response?.statusCode} - ${e.response?.data}');
      }
      return null;
    }
  }

  /// Download PDF Faktur
  Future<String?> downloadFakturPdf(String jualCode) async {
    try {
      final encodedCode = Uri.encodeComponent(jualCode);
      final uri = Uri.parse('${DioClient.baseUrl}/admin-penjualan-sales/$encodedCode/pdf');
      
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/Faktur_${jualCode.replaceAll('/', '_')}.pdf';
      
      await _dioClient.dio.downloadUri(
        uri, 
        savePath,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          responseType: ResponseType.bytes, // Mencegah dio memparsing PDF sbg JSON
        ),
      );
      return savePath;
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      if (e is DioException) {
        debugPrint('DioException details: ${e.response?.statusCode} - ${e.response?.data}');
        if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Waktu habis (timeout). Server Backend terlalu lama merespons saat membuat PDF.');
        }
        throw Exception('Gagal (${e.response?.statusCode ?? "Error"}): ${e.response?.data ?? e.message}');
      }
      throw Exception('Gagal mengunduh: $e');
    }
  }

  /// POST /api/penjualan/bayar-piutang
  Future<bool> submitTerimaCicilan(
    String jualCode,
    Map<String, dynamic> payload,
  ) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Modify payload to include necessary fields for the new endpoint
      final Map<String, dynamic> finalPayload = {
        'jual_code': jualCode,
        'metode_bayar': 'Tunai',
        ...payload,
      };

      final response = await _dioClient.dio.post(
        '/penjualan/bayar-piutang',
        data: finalPayload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['status'] == 'error') {
          _error =
              data['message'] ??
              'Gagal menerima cicilan (Server Response Error)';
          return false;
        }
        return true;
      }
      _error = response.data?['message'] ?? 'Gagal menerima cicilan';
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
          _error =
              'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
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

  /// POST /api/sales/retur
  Future<bool> submitRetur(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post('/sales/retur', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal memproses retur barang';
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
          _error =
              'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
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

  /// POST /api/customer
  Future<bool> submitCustomer(Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.post('/customer', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      _error = response.data['message'] ?? 'Gagal memproses tambah customer';
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
          _error =
              'Terjadi kesalahan: ${e.response?.statusCode ?? "Koneksi Bermasalah"}';
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
      final queryParams = <String, dynamic>{
        '_t': DateTime.now().millisecondsSinceEpoch, // Bypass cache
      };
      if (tanggal != null && tanggal.isNotEmpty) {
        queryParams['tanggal'] = tanggal;
      }

      final response = await _dioClient.dio.get(
        '/sales/dashboard',
        queryParameters: queryParams,
      );
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

  // --- REKAP & LAPORAN API ---
  Future<void> fetchRekapHarian({String? tanggal}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (tanggal != null && tanggal.isNotEmpty) {
        queryParams['date'] = tanggal;
      }

      final response = await _dioClient.dio.get(
        '/sales/rekap-harian',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          _rekapHarianData = Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch rekap harian: $e');
      _error = 'Gagal memuat rekap harian';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRekapBulanan({String? bulan, String? tahun}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (bulan != null && bulan.isNotEmpty) queryParams['bulan'] = bulan;
      if (tahun != null && tahun.isNotEmpty) queryParams['tahun'] = tahun;

      final response = await _dioClient.dio.get(
        '/sales/rekap-bulanan',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          _rekapBulananData = Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch rekap bulanan: $e');
      _error = 'Gagal memuat rekap bulanan';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRiwayatSetoran({
    String? tanggalAwal,
    String? tanggalAkhir,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      // Backend supports tanggal_awal and tanggal_akhir for date range filtering
      if (tanggalAwal != null && tanggalAwal.isNotEmpty) {
        queryParams['tanggal_awal'] = tanggalAwal;
      }
      if (tanggalAkhir != null && tanggalAkhir.isNotEmpty) {
        queryParams['tanggal_akhir'] = tanggalAkhir;
      }

      final response = await _dioClient.dio.get(
        '/sales/riwayat-setoran',
        queryParameters: queryParams,
      );
      debugPrint('👉 RESPON BACKEND RIWAYAT SETORAN: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          _riwayatSetoranData = Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch riwayat setoran: $e');
      _error = 'Gagal memuat riwayat setoran';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /api/sales/riwayat-stok-mobil
  Future<void> fetchRiwayatStokMobil({
    String? tanggalAwal,
    String? tanggalAkhir,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      if (tanggalAwal != null) queryParams['start_date'] = tanggalAwal;
      if (tanggalAkhir != null) queryParams['end_date'] = tanggalAkhir;

      final response = await _dioClient.dio.get(
        '/sales/riwayat-stok-mobil',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          _riwayatStokMobil = List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)),
          );
        } else if (data is Map) {
          if (data.containsKey('history') && data['history'] is List) {
            _riwayatStokMobil = List<Map<String, dynamic>>.from(
              data['history'].map((e) => Map<String, dynamic>.from(e)),
            );
          } else {
            // Fallback
            for (var value in data.values) {
              if (value is List) {
                _riwayatStokMobil = List<Map<String, dynamic>>.from(
                  value.map((e) => Map<String, dynamic>.from(e)),
                );
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch riwayat stok mobil: $e');
      _error = 'Gagal memuat riwayat stok mobil';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- DUMMY DATA / FALLBACKS ---

  Map<String, dynamic> getDashboardSummary() {
    if (_dashboardData != null) {
      final totalCashPaid =
          double.tryParse(
            _dashboardData!['total_lunas']?.toString() ?? '0',
          ) ??
          0;
      final totalPiutang =
          double.tryParse(
            _dashboardData!['total_belum']?.toString() ?? '0',
          ) ??
          0;
      return {
        'total_penjualan': totalCashPaid + totalPiutang, // as an estimate
        'terbayar': totalCashPaid,
        'belum_bayar': totalPiutang,
      };
    }

    double totalPenjualan = 0;
    double terbayar = 0;
    double belumBayar = 0;

    for (var trx in _salesHistory) {
      double total =
          double.tryParse(
            trx['grand_total']?.toString() ?? trx['total']?.toString() ?? '0',
          ) ??
          0;
      double dibayar =
          double.tryParse(
            trx['total_dibayar']?.toString() ??
                trx['dibayar']?.toString() ??
                '0',
          ) ??
          0;

      totalPenjualan += total;
      terbayar += dibayar;
      belumBayar += (total - dibayar);
    }

    return {
      'total_penjualan': totalPenjualan,
      'terbayar': terbayar,
      'belum_bayar': belumBayar,
    };
  }


  /// GET /api/sales/profile
  Future<void> fetchSalesProfile() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/sales/profile');
      if (response.statusCode == 200) {
        _salesProfile = response.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to fetch sales profile: $e');
      _error = 'Gagal memuat profil sales';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

    // --- Penggantian Barang (Hutang Barang) ---
  
  List<Map<String, dynamic>> _hutangBarangPending = [];
  List<Map<String, dynamic>> get hutangBarangPending => _hutangBarangPending;

  /// GET /api/penggantian-barang/pending
  Future<void> fetchHutangBarangPending() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/penggantian-barang/pending');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          _hutangBarangPending = List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch hutang barang pending: $e');
      _error = 'Gagal memuat data hutang barang';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// POST /api/penggantian-barang/{retur_code}/selesai
  Future<bool> submitPenyelesaianHutang(String returCode, {String? skuPengganti}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Escape URL path parameters correctly
      final encodedCode = Uri.encodeComponent(returCode);
      final payload = skuPengganti != null ? {'sku_pengganti': skuPengganti} : {};
      
      final response = await _dioClient.dio.post(
        '/penggantian-barang/$encodedCode/selesai',
        data: payload,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _hutangBarangPending.removeWhere((item) => item['retur_code'] == returCode);
        return true;
      }
      _error = response.data['message'] ?? 'Gagal menyelesaikan hutang barang';
      return false;
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          _error = data['message']?.toString() ?? 'Terjadi kesalahan jaringan';
        } else {
          _error = 'Terjadi kesalahan jaringan (${e.response?.statusCode ?? "Unknown"})';
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

}

