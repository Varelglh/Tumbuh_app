part of '../detailresep.dart';

final Map<String, Future<_YoutubeOembed?>> _oembedCache =
    <String, Future<_YoutubeOembed?>>{};

const String _fallbackImageUrl =
    'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?auto=format&fit=crop&w=1200&q=80';

String? _extractYoutubeId(String url) {
  final Uri? uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  if (host.contains('youtu.be')) {
    final seg = uri.pathSegments;
    if (seg.isEmpty) return null;
    final id = seg.first.trim();
    return id.isEmpty ? null : id;
  }

  if (host.contains('youtube.com')) {
    // watch?v=VIDEO_ID
    final v = uri.queryParameters['v'];
    if (v != null && v.trim().isNotEmpty) return v.trim();

    // /shorts/VIDEO_ID, /embed/VIDEO_ID
    final seg = uri.pathSegments;
    final shortsIndex = seg.indexOf('shorts');
    if (shortsIndex != -1 && seg.length > shortsIndex + 1) {
      final id = seg[shortsIndex + 1].trim();
      return id.isEmpty ? null : id;
    }
    final embedIndex = seg.indexOf('embed');
    if (embedIndex != -1 && seg.length > embedIndex + 1) {
      final id = seg[embedIndex + 1].trim();
      return id.isEmpty ? null : id;
    }
  }

  return null;
}

String _youtubeThumbUrl(String id) {
  return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

int _tryParseInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

int _extractFirstNumber(dynamic v) {
  if (v == null) return 0;
  final s = v.toString();
  final m = RegExp(r'(\d+)').firstMatch(s);
  if (m == null) return 0;
  return int.tryParse(m.group(1) ?? '') ?? 0;
}

String _coerceString(dynamic v) => (v ?? '').toString();

String _pickFirstNonEmpty(List<dynamic> candidates) {
  for (final c in candidates) {
    final s = _coerceString(c).trim();
    if (s.isNotEmpty) return s;
  }
  return '';
}

List<String> _extractLabels(Map<String, dynamic> r) {
  final Set<String> out = <String>{};

  void addToken(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return;

    // Remove wrapping quotes/brackets that often come from stringified lists.
    // Example: "[Sedang Kalori, Sedang Lemak]", "['A','B']", "[]".
    s = s.replaceAll(RegExp("^[\\[\\(\\{\\s\"']+"), '');
    s = s.replaceAll(RegExp("[\\]\\)\\}\\s\"']+\$"), '');
    s = s.trim();
    if (s.isEmpty) return;

    final lower = s.toLowerCase();
    if (lower == '[]' || lower == 'null' || lower == '-' || lower == 'nan') {
      return;
    }

    out.add(s);
  }

  void addFromPossiblyStringList(dynamic value) {
    if (value == null) return;

    if (value is List) {
      for (final e in value) {
        addToken((e ?? '').toString());
      }
      return;
    }

    final s = value.toString().trim();
    if (s.isEmpty) return;

    // Common case: backend sends list as a string.
    if (s.startsWith('[') && s.endsWith(']')) {
      final inner = s.substring(1, s.length - 1);
      if (inner.trim().isEmpty) return;
      for (final part in inner.split(',')) {
        addToken(part);
      }
      return;
    }

    // Comma-separated string.
    if (s.contains(',')) {
      for (final part in s.split(',')) {
        addToken(part);
      }
      return;
    }

    addToken(s);
  }

  addFromPossiblyStringList(r['tags']);
  addFromPossiblyStringList(r['label']);

  return out.toList();
}

Future<_YoutubeOembed?> _youtubeOembed(String videoUrl) {
  final url = videoUrl.trim();
  if (url.isEmpty) return Future.value(null);

  return _oembedCache.putIfAbsent(url, () async {
    try {
      final uri = Uri.https('www.youtube.com', '/oembed', <String, String>{
        'url': url,
        'format': 'json',
      });

      final res = await Dio().getUri<dynamic>(uri);
      final dynamic data = res.data;

      final Map<String, dynamic> m;
      if (data is Map<String, dynamic>) {
        m = data;
      } else if (data is String) {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) {
          m = parsed;
        } else {
          return null;
        }
      } else if (data is Map) {
        m = data.map((k, v) => MapEntry(k.toString(), v));
      } else {
        return null;
      }

      final authorName = (m['author_name'] ?? '').toString().trim();
      final authorUrl = (m['author_url'] ?? '').toString().trim();
      final title = (m['title'] ?? '').toString().trim();

      if (authorName.isEmpty && authorUrl.isEmpty && title.isEmpty) {
        return null;
      }
      return _YoutubeOembed(
        authorName: authorName,
        authorUrl: authorUrl,
        title: title,
      );
    } catch (_) {
      return null;
    }
  });
}

bool _looksLikeStepList(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return false;

  final lines = s
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (lines.length >= 2) return true;

  final matches = RegExp(r'(?:^|\s)(\d+)\.\s+').allMatches(s).toList();
  return matches.length >= 2 ||
      (matches.length == 1 && matches.first.start == 0);
}

List<String> _parseSteps(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return const <String>[];

  final lines = s
      .split(RegExp(r'\r?\n'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (lines.length >= 2) {
    return lines.map(_stripStepPrefix).where((e) => e.isNotEmpty).toList();
  }

  final matches = RegExp(r'(?:^|\s)(\d+)\.\s+').allMatches(s).toList();
  if (matches.length >= 2 ||
      (matches.length == 1 && matches.first.start == 0)) {
    final starts = <int>[];
    for (final m in matches) {
      final g0 = m.group(0) ?? '';
      final g1 = m.group(1) ?? '';
      final off = g1.isEmpty ? 0 : g0.indexOf(g1);
      starts.add(m.start + (off < 0 ? 0 : off));
    }

    final out = <String>[];
    for (var i = 0; i < starts.length; i++) {
      final chunkStart = starts[i];
      final nextStart = (i + 1 < starts.length) ? starts[i + 1] : s.length;
      if (chunkStart >= nextStart) continue;

      final prefix = RegExp(r'^\d+\.\s+').firstMatch(s.substring(chunkStart));
      final bodyStart = chunkStart + (prefix?.end ?? 0);
      if (bodyStart >= nextStart) continue;

      final piece = s.substring(bodyStart, nextStart).trim();
      final cleaned = _stripStepPrefix(piece);
      if (cleaned.isNotEmpty) out.add(cleaned);
    }

    if (out.isNotEmpty) return out;
  }

  return <String>[_stripStepPrefix(s)].where((e) => e.isNotEmpty).toList();
}

String _stripStepPrefix(String s) {
  var out = s.trim();
  out = out.replaceFirst(RegExp(r'^\d+\s*[\.)-]\s*'), '');
  return out.trim();
}
