import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/utils/auth_ui.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_header.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_search_field.dart';
import 'package:tumbuh_app/core/utils/youtube_thumbnail.dart';
import 'package:tumbuh_app/features/video/detailvideo.dart';
import 'package:tumbuh_app/core/services/videos_api.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final VideosApi _videosApi = VideosApi();

  List<Map<String, dynamic>> _all = <Map<String, dynamic>>[];
  bool _loading = false;
  String? _error;

  String _query = '';
  int _selectedChip = 0;
  List<String> _chips = ['Semua'];

  @override
  void initState() {
    super.initState();
    _rebuildChips();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _videosApi.fetchVideos();
      if (!mounted) return;
      setState(() {
        _all = items;
        _rebuildChips();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat video.';
        _all = <Map<String, dynamic>>[];
        _rebuildChips();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _rebuildChips() {
    final String current = (_selectedChip >= 0 && _selectedChip < _chips.length)
        ? _chips[_selectedChip]
        : 'Semua';

    final Set<String> cats = <String>{};
    for (final v in _all) {
      final String c = (v['category'] ?? '').toString().trim();
      if (c.isNotEmpty) cats.add(c);
    }

    final List<String> next = <String>['Semua', 'Terbaru', ...cats];
    _chips = next;

    final int idx = _chips.indexOf(current);
    _selectedChip = idx == -1 ? 0 : idx;
  }

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    final String s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    final int safeIndex = (_selectedChip >= 0 && _selectedChip < _chips.length)
        ? _selectedChip
        : 0;
    final selected = _chips[safeIndex];
    final selectedNorm = _norm(selected);

    final List<Map<String, dynamic>> list = _all.where((m) {
      final String title = (m['title'] ?? '').toString();
      final String authorName = (m['authorName'] ?? '').toString();
      final String category = (m['category'] ?? '').toString();
      final matchQuery =
          q.isEmpty ||
          title.toLowerCase().contains(q) ||
          authorName.toLowerCase().contains(q);

      final bool matchChip;
      if (selectedNorm == 'semua' || selectedNorm == 'terbaru') {
        matchChip = true;
      } else {
        matchChip = _norm(category) == selectedNorm;
      }
      return matchQuery && matchChip;
    }).toList();

    if (selectedNorm == 'terbaru') {
      list.sort((a, b) {
        final DateTime? da =
            _tryParseDate(a['updatedAt']) ?? _tryParseDate(a['createdAt']);
        final DateTime? db =
            _tryParseDate(b['updatedAt']) ?? _tryParseDate(b['createdAt']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    }

    return list;
  }

  Widget _buildVideoItem(Map<String, dynamic> item) {
    final String title = (item['title'] ?? '').toString();
    final String authorName = (item['authorName'] ?? '').toString();
    final String category = (item['category'] ?? '').toString();
    final String durationText = (item['durationText'] ?? '').toString();
    final int views = (item['views'] is num)
        ? (item['views'] as num).toInt()
        : int.tryParse((item['views'] ?? '').toString()) ?? 0;
    final String youtubeUrl = (item['youtubeUrl'] ?? '').toString();
    final String apiThumb = (item['thumbnailUrl'] ?? '').toString();

    final String? youtubeId = extractYoutubeVideoId(youtubeUrl);
    final String thumb = youtubeId != null
        ? youtubeHqThumbnailUrl(youtubeId)
        : apiThumb;

    final List<String> metaParts = <String>[
      if (category.trim().isNotEmpty) category.trim(),
      if (durationText.trim().isNotEmpty) durationText.trim(),
      if (views > 0) '$views view',
    ];
    final String metaLine = metaParts.join(' • ');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailVideoPage(video: item)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 128,
                      height: 82,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        child: thumb.trim().isEmpty
                            ? const Icon(Icons.broken_image, color: Colors.grey)
                            : Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value:
                                            progress.expectedTotalBytes == null
                                            ? null
                                            : progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stack) =>
                                    const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                              ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.06),
                              Colors.black.withOpacity(0.20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.play_arrow,
                              color: AppTheme.brandGreenDark,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isNotEmpty ? title.trim() : '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            authorName.isNotEmpty ? 'Oleh $authorName' : '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadVideos,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: AuthStorage().getDisplayName(),
                        builder: (context, snap) {
                          final name = (snap.data ?? 'Pengguna').trim();
                          return TumbuhHeader(
                            title:
                                'Halo, ${name.isNotEmpty ? name : 'Pengguna'}',
                            subtitle: 'Mau belajar apa hari ini ?',
                            onProfileTap: () => showLogoutDialog(context),
                            trailing: const Icon(
                              Icons.wb_sunny_outlined,
                              color: Colors.amber,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      TumbuhSearchField(
                        hintText: 'Cari video…',
                        onChanged: (v) => setState(() => _query = v),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_chips.length, (i) {
                            final selected = i == _selectedChip;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(_chips[i]),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _selectedChip = i),
                                selectedColor: AppTheme.brandGreen,
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.brandGreenDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error ?? 'Belum ada video.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildVideoItem(item),
                      );
                    }, childCount: _filtered.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
