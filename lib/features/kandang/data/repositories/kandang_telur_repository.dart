import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/produksi_telur_model.dart';
import '../models/setor_telur_model.dart';

class KandangTelurRepository {
  final DioClient _dioClient;

  KandangTelurRepository(this._dioClient);

  /// 1. Load Form Panen Telur (GET /api/produksi-telur/form?kdg_code={KDG_CODE})
  Future<ProduksiFormResponse> getProduksiForm(String kdgCode) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.produksiTelurForm,
      queryParameters: {'kdg_code': kdgCode},
    );

    final data = response.data['data'] ?? response.data;
    return ProduksiFormResponse.fromJson(data);
  }

  /// 2. Submit Laporan Panen Telur (POST /api/produksi-telur)
  Future<Map<String, dynamic>> submitProduksiTelur({
    required String kdgCode,
    required String tanggal,
    required List<Map<String, dynamic>> details,
  }) async {
    final payload = {
      'kdg_code': kdgCode,
      'tanggal': tanggal,
      'details': details,
    };

    final response = await _dioClient.dio.post(
      ApiEndpoints.produksiTelur,
      data: payload,
    );

    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  /// 3. Cek Saldo Telur Kandang Real-time (GET /api/produksi-telur/saldo-kandang?kdg_code={KDG_CODE})
  Future<List<SaldoTelurKandangItem>> getSaldoTelurKandang(String kdgCode) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.saldoTelurKandang,
      queryParameters: {'kdg_code': kdgCode},
    );

    final rawData = response.data['data'] ?? response.data;
    if (rawData is List) {
      return rawData.map((e) => SaldoTelurKandangItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  /// 4. Load Form Setor Kas ke Gudang (GET /api/setor-telur/form?kdg_code={KDG_CODE})
  Future<SetorTelurFormResponse> getSetorTelurForm(String kdgCode) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.setorTelurForm,
      queryParameters: {'kdg_code': kdgCode},
    );

    final data = response.data['data'] ?? response.data;
    return SetorTelurFormResponse.fromJson(data);
  }

  /// 5. Submit Setor Kas ke Gudang (POST /api/setor-telur)
  Future<SetorTelurResult> submitSetorTelur({
    required String kdgCode,
    required String gudangCode,
    required String tanggal,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'kdg_code': kdgCode,
      'gudang_code': gudangCode,
      'tanggal': tanggal,
      if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      'items': items,
    };

    final response = await _dioClient.dio.post(
      ApiEndpoints.setorTelur,
      data: payload,
    );

    final data = response.data['data'] ?? response.data;
    return SetorTelurResult.fromJson(data);
  }

  /// 6. Riwayat Setoran Kas Telur (GET /api/setor-telur?kdg_code=...)
  Future<List<RiwayatSetorItem>> getRiwayatSetorTelur({
    required String kdgCode,
    String? startDate,
    String? endDate,
  }) async {
    final query = <String, dynamic>{'kdg_code': kdgCode};
    if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;

    final response = await _dioClient.dio.get(
      ApiEndpoints.setorTelur,
      queryParameters: query,
    );

    dynamic listData = response.data['data'];
    if (listData is Map && listData.containsKey('data')) {
      // Pagination structure { data: { data: [...] } }
      listData = listData['data'];
    }

    if (listData is List) {
      return listData.map((e) => RiwayatSetorItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  /// 7. Detail Bukti Setoran (GET /api/setor-telur/{setor_code})
  Future<SetorTelurResult> getDetailSetorTelur(String setorCode) async {
    final response = await _dioClient.dio.get('${ApiEndpoints.setorTelur}/$setorCode');
    final data = response.data['data'] ?? response.data;
    return SetorTelurResult.fromJson(data);
  }
}
