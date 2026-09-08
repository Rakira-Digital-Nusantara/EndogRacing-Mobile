import '../../../../core/network/dio_client.dart';
import '../models/kandang_model.dart';

class KandangRepository {
  final DioClient _dioClient;

  KandangRepository(this._dioClient);

  /// Mengambil daftar semua kandang (GET /api/kandang/list)
  Future<List<KandangModel>> getKandangs() async {
    final response = await _dioClient.dio.get('/kandang/list');
    
    List<dynamic> rawData;
    if (response.data is List) {
      rawData = response.data as List;
    } else {
      rawData = response.data['data'] as List;
    }
    
    return rawData.map((json) => KandangModel.fromJson(json)).toList();
  }
}
