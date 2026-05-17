import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:math';

import 'api_client.dart';

class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static String? _extractMessageFromMapLikeString(String s) {
    final String raw = s.trim();
    if (raw.isEmpty) return null;

    // Matches strings like:
    // {statusCode: 401, message: Username atau Password salah, timestamp: ...}
    // {message=..., ...}
    final re = RegExp(
      r'(?:^|[\{,])\s*message\s*[:=]\s*([^,\}]+)',
      caseSensitive: false,
    );
    final m = re.firstMatch(raw);
    if (m == null) return null;

    var v = (m.group(1) ?? '').trim();
    if (v.isEmpty) return null;

    // Strip wrapping quotes if any.
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1).trim();
    }

    return v.isEmpty ? null : v;
  }

  static String _normalizeAuthMessage(String message) {
    final String s = message.trim();
    if (s.isEmpty) return s;
    final lower = s.toLowerCase();

    if (lower.contains('username') &&
        lower.contains('password') &&
        lower.contains('salah')) {
      return 'Username atau kata sandi salah.';
    }

    if (lower == 'unauthorized' || lower.contains('unauthorized')) {
      return 'Username atau kata sandi salah.';
    }

    return s;
  }

  static String _uuidV4() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));

    // Per RFC 4122 v4
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String b(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
    return '${b(0)}${b(1)}${b(2)}${b(3)}-${b(4)}${b(5)}-${b(6)}${b(7)}-${b(8)}${b(9)}-${b(10)}${b(11)}${b(12)}${b(13)}${b(14)}${b(15)}';
  }

  Future<AuthLoginResult> login({
    required String username,
    required String password,
  }) async {
    final String u = username.trim();
    final String pass = password;

    if (u.isEmpty) {
      throw ArgumentError('Username is empty');
    }
    if (pass.isEmpty) {
      throw ArgumentError('Password is empty');
    }

    final Response<dynamic> res = await _client.dio.post(
      '/auth/login',
      data: <String, dynamic>{'username': u, 'password': pass},
    );

    final token = _extractToken(res.data);
    final name = _extractUserName(res.data);
    final phone = _extractPhoneNumber(res.data);
    return AuthLoginResult(token: token, name: name, phoneNumber: phone);
  }

  static String? _extractPhoneNumber(dynamic body) {
    dynamic cur = body;

    for (var i = 0; i < 5; i++) {
      if (cur is Map) {
        final dynamic direct =
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

        if (direct != null) {
          final s = direct.toString().trim();
          if (s.isNotEmpty) return s;
        }

        cur = cur['data'];
      } else {
        break;
      }
    }

    return null;
  }

  Future<void> register({
    required String username,
    required String phoneNumber,
    required String password,
  }) async {
    final String u = username.trim();
    final String p = phoneNumber.trim();
    final String pass = password;

    if (u.isEmpty) {
      throw ArgumentError('Username is empty');
    }
    if (p.isEmpty) {
      throw ArgumentError('Phone number is empty');
    }
    if (pass.isEmpty) {
      throw ArgumentError('Password is empty');
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'username': u,
      'phoneNumber': p,
      'password': pass,
    };

    try {
      await _client.dio.post('/auth/register', data: payload);
    } on DioException catch (e) {
      final dynamic data = e.response?.data;
      final String msg = (_extractMessage(data) ?? '').toLowerCase();

      // Backend compatibility: some deployments incorrectly require `id` in request
      // and throw a 500 like: "null value in column \"id\" of relation \"users\"".
      final bool looksLikeMissingId =
          msg.contains('null value') &&
          msg.contains('column') &&
          msg.contains('id');

      if (!looksLikeMissingId) rethrow;

      final Map<String, dynamic> retryPayload = <String, dynamic>{
        ...payload,
        'id': _uuidV4(),
        // Legacy keys (in case backend still expects old names)
        'name': u,
        'phone': p,
      };

      await _client.dio.post('/auth/register', data: retryPayload);
    }
  }

  static String? _extractToken(dynamic body) {
    dynamic cur = body;

    for (var i = 0; i < 3; i++) {
      if (cur is Map) {
        dynamic token =
            cur['token'] ??
            cur['accessToken'] ??
            cur['access_token'] ??
            cur['jwt'] ??
            cur['data']?['token'] ??
            cur['data']?['accessToken'] ??
            cur['data']?['access_token'];

        if (token != null) {
          final String t = token.toString().trim();
          return t.isEmpty ? null : t;
        }

        cur = cur['data'];
      } else {
        break;
      }
    }

    return null;
  }

  static String? _extractUserName(dynamic body) {
    dynamic cur = body;

    for (var i = 0; i < 4; i++) {
      if (cur is Map) {
        final dynamic direct =
            cur['name'] ??
            cur['fullName'] ??
            cur['fullname'] ??
            cur['username'] ??
            cur['userName'] ??
            cur['user']?['name'] ??
            cur['user']?['fullName'] ??
            cur['data']?['name'] ??
            cur['data']?['fullName'] ??
            cur['data']?['user']?['name'] ??
            cur['data']?['user']?['fullName'];

        if (direct != null) {
          final s = direct.toString().trim();
          if (s.isNotEmpty) return s;
        }

        cur = cur['data'];
      } else {
        break;
      }
    }

    return null;
  }

  static String extractErrorMessage(Object error) {
    if (error is ArgumentError) {
      final m = (error.message ?? '').toString().toLowerCase();
      if (m.contains('username')) return 'Username wajib diisi.';
      if (m.contains('password')) return 'Kata sandi wajib diisi.';
      if (m.contains('phone')) return 'Nomor HP wajib diisi.';
      return 'Input tidak valid.';
    }

    if (error is DioException) {
      final int? status = error.response?.statusCode;
      final data = error.response?.data;
      final String? msg = _extractMessage(data);
      final String? cleaned = (msg == null)
          ? null
          : (_extractMessageFromMapLikeString(msg) ?? msg).trim();
      final String? normalized = (cleaned == null || cleaned.isEmpty)
          ? null
          : _normalizeAuthMessage(cleaned);

      // Prefer user-friendly messages for common cases.
      if (status == 401) {
        return (normalized?.trim().isNotEmpty == true)
            ? normalized!.trim()
            : 'Username atau kata sandi salah.';
      }
      if (status == 403) {
        return (normalized?.trim().isNotEmpty == true)
            ? normalized!.trim()
            : 'Akses ditolak.';
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Coba lagi.';
        case DioExceptionType.connectionError:
          return 'Tidak ada koneksi internet / server tidak bisa diakses.';
        default:
          break;
      }

      return normalized ?? (error.message ?? 'Gagal memproses permintaan.');
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }

  static String? _extractMessage(dynamic body) {
    if (body is Map) {
      final dynamic msg = body['message'] ?? body['error'] ?? body['msg'];
      if (msg != null) {
        if (msg is Map) {
          final nested = _extractMessage(msg);
          if (nested != null && nested.trim().isNotEmpty) return nested.trim();
        }
        if (msg is List) {
          // If list contains a single map, prefer extracting from that map.
          if (msg.length == 1 && msg.first is Map) {
            final nested = _extractMessage(msg.first);
            if (nested != null && nested.trim().isNotEmpty) {
              return nested.trim();
            }
          }
          final combined = msg.map((e) => e.toString()).join('\n').trim();
          if (combined.isNotEmpty) return combined;
        }
        final s = msg.toString().trim();
        if (s.isNotEmpty) return s;
      }

      // Common variations
      final dynamic detail =
          body['detail'] ?? body['details'] ?? body['error_description'];
      if (detail != null) {
        final s = detail.toString().trim();
        if (s.isNotEmpty) return s;
      }

      final data = body['data'];
      if (data is Map) {
        final dynamic msg2 = data['message'] ?? data['error'] ?? data['msg'];
        if (msg2 != null) {
          if (msg2 is List) {
            final combined = msg2.map((e) => e.toString()).join('\n').trim();
            if (combined.isNotEmpty) return combined;
          }
          final s = msg2.toString().trim();
          if (s.isNotEmpty) return s;
        }
      }
    }
    if (body is String) {
      final s = body.trim();
      if (s.isEmpty) return null;

      // Fast-path for map-like strings (Map.toString()).
      final extractedFromMapString = _extractMessageFromMapLikeString(s);
      if (extractedFromMapString != null &&
          extractedFromMapString.trim().isNotEmpty) {
        return extractedFromMapString.trim();
      }

      // If backend sends JSON as string, decode and retry.
      if ((s.startsWith('{') && s.endsWith('}')) ||
          (s.startsWith('[') && s.endsWith(']'))) {
        try {
          final decoded = jsonDecode(s);
          final extracted = _extractMessage(decoded);
          if (extracted != null && extracted.trim().isNotEmpty) {
            return extracted.trim();
          }
        } catch (_) {
          // ignore and fall through
        }
      }

      // Handle non-JSON backend shape like: "{statusCode: 401, message: ..., timestamp: ...}"
      final lower = s.toLowerCase();
      final int idx = lower.indexOf('message:');
      if (idx >= 0) {
        final after = s.substring(idx + 'message:'.length).trim();
        final int endIdx = after.indexOf(',');
        final candidate = (endIdx >= 0 ? after.substring(0, endIdx) : after)
            .trim();
        if (candidate.isNotEmpty) return candidate;
      }

      return s;
    }
    return null;
  }
}

class AuthLoginResult {
  final String? token;
  final String? name;
  final String? phoneNumber;

  const AuthLoginResult({
    required this.token,
    required this.name,
    required this.phoneNumber,
  });
}
