import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/absensi_model.dart';

class AbsensiRepository {
  final DioClient _dioClient;

  AbsensiRepository(this._dioClient);

  Future<List<AbsensiModel>> getAbsensiHistory() async {
    try {
      final response = await _dioClient.dio.get('/absensi');
      final data = response.data['data'] as List;
      return data.map((e) => AbsensiModel.fromJson(e)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitAbsensi({
    required String tipeAbsen, // "Masuk" atau "Pulang"
    required String photoPath, // local file path
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Menggunakan multipart/form-data karena kita mengirim file fisik
      final formData = FormData.fromMap({
        'abs_tipe_absen': tipeAbsen,
        'abs_latitude': latitude,
        'abs_longitude': longitude,
        'abs_foto_selfie': await MultipartFile.fromFile(photoPath, filename: 'selfie.jpg'),
      });

      await _dioClient.dio.post(
        '/absensi',
        data: formData,
      );
    } catch (e) {
      rethrow;
    }
  }
}
