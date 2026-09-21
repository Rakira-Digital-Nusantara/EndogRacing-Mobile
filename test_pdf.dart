import 'package:dio/dio.dart';
void main() async {
  final dio = Dio();
  try {
    print('Downloading...');
    final response = await dio.get(
      'https://api-endogracing.rakiradigital.com/api/admin-penjualan-sales/INV%2F202609%2F0013/pdf',
      options: Options(responseType: ResponseType.bytes)
    );
    print('Success: ${response.statusCode}');
    print('Content-Type: ${response.headers.value("content-type")}');
    print('Size: ${(response.data as List).length} bytes');
  } catch (e) {
    if (e is DioException) {
      print('Failed: ${e.response?.statusCode}');
    } else {
      print('Error: $e');
    }
  }
}
