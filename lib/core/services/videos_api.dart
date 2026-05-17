import 'package:dio/dio.dart';

import 'api_client.dart';

class VideosApi {
  VideosApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const String _fallbackThumbUrl =
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=1200&q=80';

  Future<List<Map<String, dynamic>>> fetchVideos() async {
    final Response<dynamic> res = await _client.dio.get('/videos');
    final dynamic body = res.data;

    final List<dynamic> items;
    if (body is Map<String, dynamic> && body['data'] is List) {
      items = body['data'] as List<dynamic>;
    } else if (body is List) {
      items = body;
    } else {
      throw const FormatException('Unexpected /videos response shape');
    }

    return items.map(_mapVideo).toList();
  }

  Map<String, dynamic> _mapVideo(dynamic raw) {
    final Map<String, dynamic> m = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
              ? raw.map((k, v) => MapEntry('$k', v))
              : <String, dynamic>{});

    final externalLinksRaw = m['externalLinks'];
    final List<Map<String, String>> externalLinks = (externalLinksRaw is List)
        ? externalLinksRaw.whereType<dynamic>().map((e) {
            final Map<String, dynamic> em = e is Map<String, dynamic>
                ? e
                : (e is Map
                      ? e.map((k, v) => MapEntry('$k', v))
                      : <String, dynamic>{});
            final String url = (em['url'] ?? '').toString();
            final String title = (em['title'] ?? '').toString();
            return <String, String>{'url': url, 'title': title};
          }).toList()
        : <Map<String, String>>[];

    final String thumbnailUrl = (m['thumbnailUrl'] ?? '').toString();

    return <String, dynamic>{
      'id': (m['id'] ?? '').toString(),
      'title': (m['title'] ?? '').toString(),
      'description': (m['description'] ?? '').toString(),
      'summary': (m['summary'] ?? '').toString(),
      'authorName': (m['authorName'] ?? '').toString(),
      'youtubeUrl': (m['youtubeUrl'] ?? '').toString(),
      'category': (m['category'] ?? '').toString(),
      'duration': _toInt(m['duration']) ?? 0,
      'durationText': (m['durationText'] ?? '').toString(),
      'thumbnailUrl': _sanitizeThumbUrl(thumbnailUrl),
      'views': _toInt(m['views']) ?? 0,
      'externalLinks': externalLinks,
      'status': (m['status'] ?? '').toString(),
      'createdAt': (m['createdAt'] ?? '').toString(),
      'updatedAt': (m['updatedAt'] ?? '').toString(),
    };
  }

  static String _sanitizeThumbUrl(String url) {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return _fallbackThumbUrl;

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _fallbackThumbUrl;
    }

    // Host yang sering bermasalah SSL di proyek ini.
    final String host = uri.host.toLowerCase();
    if (host.contains('link-foto.com')) {
      return _fallbackThumbUrl;
    }

    return trimmed;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
