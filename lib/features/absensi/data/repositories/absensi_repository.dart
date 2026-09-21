import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/absensi_model.dart';

class AbsensiRepository {
  final DioClient _dioClient;

  AbsensiRepository(this._dioClient);

  Future<List<AbsensiModel>> getAbsensiHistory({bool isSales = false}) async {
    try {
      final endpoint = isSales ? '/sales/absensi' : '/absensi';
      final response = await _dioClient.dio.get(endpoint);
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
    bool isSales = false,
  }) async {
    try {
      FormData formData;
      String endpoint;
      
      if (isSales) {
        endpoint = '/sales/absensi';
        formData = FormData.fromMap({
          'tipe_absen': tipeAbsen,
          'latitude': latitude,
          'longitude': longitude,
          'foto_absensi': await MultipartFile.fromFile(photoPath, filename: 'selfie.jpg'),
        });
      } else {
        endpoint = '/absensi';
        formData = FormData.fromMap({
          'abs_tipe_absen': tipeAbsen,
          'abs_latitude': latitude,
          'abs_longitude': longitude,
          'abs_foto_selfie': await MultipartFile.fromFile(photoPath, filename: 'selfie.jpg'),
        });
      }

      await _dioClient.dio.post(
        endpoint,
        data: formData,
      );
    } catch (e) {
      rethrow;
    }
  }
}
