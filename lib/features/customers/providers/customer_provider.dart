import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:endog_racing/core/network/dio_client.dart';

class CustomerProvider with ChangeNotifier {
  final DioClient _dioClient;

  CustomerProvider(this._dioClient);

  bool _isLoading = false;
  String _error = '';
  List<Map<String, dynamic>> _customers = [];

  bool get isLoading => _isLoading;
  String get error => _error;
  List<Map<String, dynamic>> get customers => _customers;

  /// Fetch list of customers from GET /api/customers
  Future<void> fetchCustomers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.get('/customers');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is List) {
          _customers = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } else {
        _error = response.data['message'] ?? 'Gagal memuat data pelanggan';
      }
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data?['message'] ?? 'Gagal terhubung ke server';
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update customer data via PUT /api/customers/{customer_code}
  Future<bool> updateCustomer(String customerCode, Map<String, dynamic> payload) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final response = await _dioClient.dio.put(
        '/customers/$customerCode',
        data: payload,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map && data['status'] == 'error') {
           _error = data['message'] ?? 'Gagal mengubah data pelanggan';
           return false;
        }
        return true;
      }
      _error = response.data?['message'] ?? 'Gagal mengubah data pelanggan';
      return false;
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data?['message'] ?? 'Terjadi kesalahan jaringan';
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
