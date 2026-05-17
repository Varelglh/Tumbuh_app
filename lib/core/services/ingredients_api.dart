import 'package:dio/dio.dart';

import 'api_client.dart';

class IngredientsApi {
  IngredientsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<String>> fetchIngredientNames() async {
    final Response<dynamic> res = await _client.dio.get('/ingredients');
    final dynamic body = res.data;

    final List<dynamic> items;
    if (body is Map<String, dynamic> && body['data'] is List) {
      items = body['data'] as List<dynamic>;
    } else if (body is List) {
      items = body;
    } else {
      throw const FormatException('Unexpected /ingredients response shape');
    }

    final List<String> out = <String>[];
    final Set<String> seen = <String>{};

    for (final dynamic raw in items) {
      String name = '';
      if (raw is String) {
        name = raw;
      } else if (raw is Map) {
        final dynamic n = raw['name'] ?? raw['title'] ?? raw['ingredient'];
        if (n != null) name = n.toString();
      }

      final String trimmed = name.trim();
      if (trimmed.isEmpty) continue;

      final String key = _norm(trimmed);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      out.add(trimmed);
    }

    return out;
  }

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
