import 'package:dio/dio.dart';
import 'dart:convert';

import 'api_client.dart';

class UsersApi {
  UsersApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<String?> fetchDisplayNameById(String userId) async {
    final String id = userId.trim();
    if (id.isEmpty) return null;

    try {
      final Response<dynamic> res = await _client.dio.get('/users/$id');
      return _extractDisplayName(res.data);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> fetchPhoneById({
    required String token,
    required String userId,
  }) async {
    final String t = token.trim();
    final String id = userId.trim();
    if (t.isEmpty || id.isEmpty) return null;

    try {
      final Response<dynamic> res = await _client.dio.get(
        '/users/$id',
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $t',
            'Accept': 'application/json',
          },
        ),
      );
      return _extractPhoneNumber(res.data);
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch phone number for the currently logged-in user.
  ///
  /// Backend endpoint conventions vary; this method tries a few common ones.
  Future<String?> fetchMyPhone({required String token}) async {
    final String t = token.trim();
    if (t.isEmpty) return null;

    Future<String?> tryGet(String path) async {
      final Response<dynamic> res = await _client.dio.get(
        path,
        options: Options(
          headers: <String, dynamic>{
            'Authorization': 'Bearer $t',
            'Accept': 'application/json',
          },
        ),
      );
      return _extractPhoneNumber(res.data);
    }

    try {
      final v = await tryGet('/users/me');
      if (v != null && v.trim().isNotEmpty) return v.trim();
    } on DioException {
      // ignore and fall through
    } catch (_) {
      // ignore and fall through
    }

    try {
      final v = await tryGet('/auth/me');
      if (v != null && v.trim().isNotEmpty) return v.trim();
    } on DioException {
      // ignore and fall through
    } catch (_) {
      // ignore and fall through
    }

    try {
      final v = await tryGet('/me');
      if (v != null && v.trim().isNotEmpty) return v.trim();
    } on DioException {
      // ignore
    } catch (_) {
      // ignore
    }

    return null;
  }

  /// Best-effort JWT decode (no signature verification) to extract user id.
  static String? extractUserIdFromJwt(String jwt) {
    final String t = jwt.trim();
    if (t.isEmpty) return null;

    final parts = t.split('.');
    if (parts.length < 2) return null;

    try {
      final String payloadPart = parts[1];
      final String normalized = base64Url.normalize(payloadPart);
      final String jsonStr = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return null;

      final dynamic id =
          decoded['sub'] ??
          decoded['userId'] ??
          decoded['user_id'] ??
          decoded['id'] ??
          decoded['uuid'];

      final String s = (id ?? '').toString().trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  static String? _extractDisplayName(dynamic body) {
    dynamic cur = body;

    for (var i = 0; i < 3; i++) {
      if (cur is Map) {
        final dynamic name =
            cur['name'] ??
            cur['fullName'] ??
            cur['fullname'] ??
            cur['username'] ??
            cur['userName'] ??
            cur['data']?['name'] ??
            cur['data']?['fullName'] ??
            cur['data']?['username'] ??
            cur['user']?['name'] ??
            cur['user']?['fullName'] ??
            cur['user']?['username'];

        if (name != null) {
          final String s = name.toString().trim();
          if (s.isNotEmpty) return s;
        }

        cur = cur['data'];
      } else {
        break;
      }
    }

    return null;
  }

  static String? _extractPhoneNumber(dynamic body) {
    dynamic cur = body;

    for (var i = 0; i < 5; i++) {
      if (cur is Map) {
        final dynamic phone =
            cur['phoneNumber'] ??
            cur['phone_number'] ??
            cur['phone'] ??
            cur['noHp'] ??
            cur['noHP'] ??
            cur['telp'] ??
            cur['telepon'] ??
            cur['user']?['phoneNumber'] ??
            cur['user']?['phone_number'] ??
            cur['user']?['phone'] ??
            cur['user']?['noHp'] ??
            cur['data']?['phoneNumber'] ??
            cur['data']?['phone_number'] ??
            cur['data']?['phone'] ??
            cur['data']?['noHp'] ??
            cur['data']?['user']?['phoneNumber'] ??
            cur['data']?['user']?['phone_number'] ??
            cur['data']?['user']?['phone'] ??
            cur['data']?['user']?['noHp'];

        if (phone != null) {
          final String s = phone.toString().trim();
          if (s.isNotEmpty) return s;
        }

        cur = cur['data'];
      } else {
        break;
      }
    }

    return null;
  }
}
