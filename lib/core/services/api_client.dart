import 'package:dio/dio.dart';

import '../utils/app_constants.dart';

class ApiClient {
  ApiClient({Dio? dio}) : dio = dio ?? _buildDio();

  final Dio dio;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
  }
}
