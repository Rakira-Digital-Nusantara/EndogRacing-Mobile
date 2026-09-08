import 'dart:convert';
import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(baseUrl: 'https://endog-racing.rakiradgn.com/api')); // Assuming this is the base URL or similar
  try {
    // We need auth token though. I'll just look at the logs instead!
  } catch (e) {
    print(e);
  }
}
