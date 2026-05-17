import 'package:dio/dio.dart';

import 'api_client.dart';
import 'auth_storage.dart';

class RecipesApi {
  RecipesApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const String _fallbackImageUrl =
      'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?auto=format&fit=crop&w=1200&q=80';

  Future<List<Map<String, dynamic>>> fetchRecipes() async {
    final Response<dynamic> res = await _client.dio.get('/recipes');
    final dynamic body = res.data;

    final List<dynamic> items;
    if (body is Map<String, dynamic> && body['data'] is List) {
      items = body['data'] as List<dynamic>;
    } else if (body is List) {
      items = body;
    } else {
      throw const FormatException('Unexpected /recipes response shape');
    }

    return items.map(_mapRecipe).toList();
  }

  Future<List<Map<String, dynamic>>> fetchLikedRecipesMe({
    String? token,
  }) async {
    final String? t = (token == null || token.trim().isEmpty)
        ? await AuthStorage().getToken()
        : token.trim();
    if (t == null || t.isEmpty) {
      throw StateError('Not logged in');
    }

    final Response<dynamic> res = await _client.dio.get(
      '/recipes/liked/me',
      options: Options(
        headers: <String, dynamic>{
          'Authorization': 'Bearer $t',
          'Accept': 'application/json',
        },
      ),
    );
    final dynamic body = res.data;

    final List<dynamic> items;
    if (body is Map<String, dynamic> && body['data'] is List) {
      items = body['data'] as List<dynamic>;
    } else if (body is List) {
      items = body;
    } else {
      throw const FormatException(
        'Unexpected /recipes/liked/me response shape',
      );
    }

    return items.map(_mapRecipe).toList();
  }

  Future<void> likeRecipe(String id, {String? token}) async {
    final String rid = id.trim();
    if (rid.isEmpty) {
      throw ArgumentError('Recipe id is empty');
    }

    final String? t = (token == null || token.trim().isEmpty)
        ? await AuthStorage().getToken()
        : token.trim();
    final Options? authOptions = (t == null || t.isEmpty)
        ? null
        : Options(
            headers: <String, dynamic>{
              'Authorization': 'Bearer $t',
              'Accept': 'application/json',
            },
          );

    // API endpoint per request: https://tumbuh-production.up.railway.app/recipes/{id}like
    // Keep a fallback to /recipes/{id}/like for compatibility.
    try {
      await _client.dio.post('/recipes/${rid}like', options: authOptions);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404) {
        await _client.dio.post('/recipes/$rid/like', options: authOptions);
        return;
      }
      rethrow;
    }
  }

  Future<void> unlikeRecipe(String id, {String? token}) async {
    // Backend uses a single toggle endpoint (like = like/unlike).
    return likeRecipe(id, token: token);
  }

  Map<String, dynamic> _mapRecipe(dynamic raw) {
    final Map<String, dynamic> m = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
              ? raw.map((k, v) => MapEntry('$k', v))
              : <String, dynamic>{});

    final String id = (m['id'] ?? m['_id'] ?? '').toString();
    final String name = (m['name'] ?? '').toString();
    final String description = (m['description'] ?? '').toString();
    final String ingredients = (m['ingredients'] ?? '').toString();
    final String recipeDetails = (m['recipeDetails'] ?? '').toString();
    final String tools = (m['tools'] ?? '').toString();
    final String videoUrl = (m['videoUrl'] ?? '').toString();
    final String instructions = (m['instructions'] ?? '').toString();

    final int cookingTime = _toInt(m['cookingTime']) ?? 0;
    final int caloriesValue = _toInt(m['caloriesValue']) ?? 0;

    final String label = (m['label'] ?? '').toString();
    final String category = (m['category'] ?? '').toString();

    // Backend may send iconStatus as bool/num/string/list.
    // Keep raw for UI (icon/text), and also keep a normalized bool for existing filters.
    final dynamic iconStatusRaw = m['iconStatus'];
    final bool iconStatus = _toBool(iconStatusRaw);

    final String imageUrl = (m['imageUrl'] ?? '').toString();

    // Keep raw fields too for detail page.
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'recipeDetails': recipeDetails,
      'tools': tools,
      'videoUrl': videoUrl,
      'instructions': instructions,
      'cookingTime': cookingTime,
      'caloriesValue': caloriesValue,
      'label': label,
      'category': category,
      'iconStatus': iconStatus,
      'iconStatusRaw': iconStatusRaw,
      'imageUrl': _sanitizeImageUrl(imageUrl),

      // For compatibility with existing list card code patterns.
      'title': name,
      'subtitle': category,
    };
  }

  static String _sanitizeImageUrl(String url) {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return _fallbackImageUrl;

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _fallbackImageUrl;
    }

    final String host = uri.host.toLowerCase();
    if (host.contains('link-foto.com')) {
      return _fallbackImageUrl;
    }

    return trimmed;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;

    if (v is List) {
      for (final e in v) {
        if (_toBool(e)) return true;
        final s = (e ?? '').toString().toLowerCase();
        if (s.contains('populer') || s.contains('popular')) return true;
      }
      return false;
    }

    final String s = v.toString().trim().toLowerCase();
    if (s.isEmpty) return false;
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s.contains('populer') || s.contains('popular')) return true;
    return false;
  }
}
