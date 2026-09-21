import 'package:dio/dio.dart';
void main() async {
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  try {
    print('Downloading literal slashes...');
    final response = await dio.get(
      'https://api-endogracing.rakiradigital.com/api/admin-penjualan-sales/INV/202609/0013/pdf',
      options: Options(responseType: ResponseType.bytes)
    );
    print('Success: ${response.statusCode}');
  } catch (e) {
    if (e is DioException) {
      print('Failed: ${e.response?.statusCode}');
    } else {
      print('Error: $e');
    }
  }
}
