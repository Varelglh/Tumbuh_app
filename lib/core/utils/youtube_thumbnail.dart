String? extractYoutubeVideoId(String url) {
  final String raw = url.trim();
  if (raw.isEmpty) return null;

  Uri? uri = Uri.tryParse(raw);
  uri ??= Uri.tryParse('https://$raw');
  if (uri == null) return null;

  final String host = uri.host.toLowerCase();
  final List<String> seg = uri.pathSegments;

  // 1) https://youtu.be/<id>
  if (host == 'youtu.be') {
    if (seg.isEmpty) return null;
    return _sanitizeYoutubeId(seg.first);
  }

  // 2) https://www.youtube.com/watch?v=<id>
  if (host.contains('youtube.com') || host.contains('youtube-nocookie.com')) {
    final String? v = uri.queryParameters['v'];
    if (v != null && v.trim().isNotEmpty) return _sanitizeYoutubeId(v);

    // 3) /embed/<id>, /shorts/<id>
    if (seg.length >= 2) {
      final String first = seg.first.toLowerCase();
      if (first == 'embed' || first == 'shorts') {
        return _sanitizeYoutubeId(seg[1]);
      }
    }
  }

  return null;
}

String youtubeHqThumbnailUrl(String videoId) {
  return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

String youtubeMaxResThumbnailUrl(String videoId) {
  return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
}

String? _sanitizeYoutubeId(String id) {
  final String t = id.trim();
  if (t.isEmpty) return null;

  // YouTube videoId umumnya 11 chars, tapi kita longgarkan sedikit.
  final RegExp ok = RegExp(r'^[a-zA-Z0-9_-]{6,20}$');
  return ok.hasMatch(t) ? t : null;
}
