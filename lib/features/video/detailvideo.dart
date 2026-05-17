import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/utils/youtube_thumbnail.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailVideoPage extends StatelessWidget {
  final Map<String, dynamic> video;
  const DetailVideoPage({super.key, required this.video});

  static const String _fallbackThumbUrl =
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=1200&q=80';

  Map<String, dynamic> get _v => video;

  static Future<void> _openUrl(String url) async {
    final String u = url.trim();
    if (u.isEmpty) return;
    final Uri? uri = Uri.tryParse(u);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final String category = (_v['category'] ?? '').toString();
    final String title = (_v['title'] ?? '').toString();
    final String authorName = (_v['authorName'] ?? '').toString();
    final String youtubeUrl = (_v['youtubeUrl'] ?? '').toString();
    final String description = (_v['description'] ?? '').toString();
    final String summary = (_v['summary'] ?? '').toString();
    final String durationText = (_v['durationText'] ?? '').toString();
    final int duration = (_v['duration'] is num)
        ? (_v['duration'] as num).toInt()
        : int.tryParse((_v['duration'] ?? '').toString()) ?? 0;
    final int views = (_v['views'] is num)
        ? (_v['views'] as num).toInt()
        : int.tryParse((_v['views'] ?? '').toString()) ?? 0;

    final String durationLabel = durationText.isNotEmpty
        ? durationText
        : (duration > 0 ? '$duration detik' : '-');
    final String viewsLabel = views > 0 ? views.toString() : '-';

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category.isNotEmpty ? category : 'Video',
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPlayerSection(youtubeUrl: youtubeUrl),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : '-',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authorName.isNotEmpty ? 'Oleh $authorName' : '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    category: category,
                    durationLabel: durationLabel,
                    viewsLabel: viewsLabel,
                    youtubeUrl: youtubeUrl,
                  ),
                  const SizedBox(height: 16),
                  _buildTextSection(title: 'Deskripsi', body: description),
                  const SizedBox(height: 16),
                  _buildTextSection(
                    title: 'Isi Video',
                    body: summary,
                    richBody: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichBody(String raw) {
    final String source = raw.trim();
    if (source.isEmpty) {
      return const Text(
        '-',
        style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
      );
    }

    final List<_ContentBlock> blocks = _parseContentBlocks(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < blocks.length; i++) ...[
          _ContentBlockView(block: blocks[i]),
          if (i != blocks.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<_ContentBlock> _parseContentBlocks(String input) {
    String normalized = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final List<String> parts = normalized
        .split(RegExp(r'\n+| {2,}'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final List<_ContentBlock> blocks = [];
    for (final String part in parts) {
      if (_looksLikeHeading(part)) {
        blocks.add(_ContentBlock.heading(_cleanHeading(part)));
        continue;
      }

      final _BulletParts? bullet = _tryParseBullet(part);
      if (bullet != null) {
        blocks.add(
          _ContentBlock.bullet(title: bullet.title, body: bullet.body),
        );
        continue;
      }

      blocks.add(_ContentBlock.paragraph(part));
    }
    return blocks;
  }

  String _cleanHeading(String s) {
    String t = s.trim();
    if (t.endsWith(':')) t = t.substring(0, t.length - 1).trim();
    return t;
  }

  bool _looksLikeHeading(String s) {
    final String t = s.trim();
    if (t.isEmpty) return false;
    if (t.endsWith('?')) return true;
    if (t.endsWith(':')) return true;

    // Heuristik sederhana: judul biasanya pendek, tidak berakhiran titik,
    // dan tidak mengandung pola "Label: isi".
    if (t.length > 60) return false;
    if (t.contains('.')) return false;
    if (t.contains(':')) return false;

    final String first = t.characters.first;
    final bool firstIsUpper = RegExp(r'[A-Z]').hasMatch(first);
    if (!firstIsUpper) return false;

    final int wordCount = t.split(RegExp(r'\s+')).length;
    return wordCount <= 8;
  }

  _BulletParts? _tryParseBullet(String s) {
    final int idx = s.indexOf(':');
    if (idx <= 0) return null;
    if (idx >= s.length - 1) {
      return null; // "Judul:" (tanpa isi) sudah ditangani sebagai heading
    }

    final String left = s.substring(0, idx).trim();
    final String right = s.substring(idx + 1).trim();
    if (left.isEmpty || right.isEmpty) return null;

    // Hindari memformat URL sebagai bullet.
    if (left.toLowerCase().contains('http')) return null;
    if (left.length > 60) return null;
    return _BulletParts(left, right);
  }

  Widget _buildVideoPlayerSection({required String youtubeUrl}) {
    final String apiThumb = (_v['thumbnailUrl'] ?? '').toString();
    final String? youtubeId = extractYoutubeVideoId(youtubeUrl);
    final String primaryThumb = youtubeId != null
        ? youtubeMaxResThumbnailUrl(youtubeId)
        : (apiThumb.isNotEmpty ? apiThumb : _fallbackThumbUrl);
    final String secondaryThumb = youtubeId != null
        ? youtubeHqThumbnailUrl(youtubeId)
        : (apiThumb.isNotEmpty ? apiThumb : _fallbackThumbUrl);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: youtubeUrl.trim().isNotEmpty ? () => _openUrl(youtubeUrl) : null,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                primaryThumb,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  secondaryThumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.network(_fallbackThumbUrl, fit: BoxFit.cover),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String category,
    required String durationLabel,
    required String viewsLabel,
    required String youtubeUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Kategori', category.isNotEmpty ? category : '-'),
          const SizedBox(height: 10),
          _infoRow('Durasi', durationLabel),
          const SizedBox(height: 10),
          _infoRow('View', viewsLabel),
          const SizedBox(height: 10),
          _infoUrlRow(youtubeUrl),
        ],
      ),
    );
  }

  Widget _buildTextSection({
    required String title,
    required String body,
    bool richBody = false,
  }) {
    final String text = body.trim().isNotEmpty ? body.trim() : '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (richBody)
            _buildRichBody(text)
          else ...[
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.muted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '-',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoUrlRow(String url) {
    final String u = url.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 84,
          child: Text(
            'URL Video',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.muted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: u.isEmpty
              ? const Text(
                  '-',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _openUrl(u),
                      child: const Text(
                        'Buka Video',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.brandGreen,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      u,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ContentBlock {
  final _ContentBlockType type;
  final String text;
  final String? bulletTitle;
  final String? bulletBody;

  const _ContentBlock._(
    this.type, {
    required this.text,
    this.bulletTitle,
    this.bulletBody,
  });

  factory _ContentBlock.heading(String title) =>
      _ContentBlock._(_ContentBlockType.heading, text: title);

  factory _ContentBlock.paragraph(String paragraph) =>
      _ContentBlock._(_ContentBlockType.paragraph, text: paragraph);

  factory _ContentBlock.bullet({required String title, required String body}) =>
      _ContentBlock._(
        _ContentBlockType.bullet,
        text: '',
        bulletTitle: title,
        bulletBody: body,
      );
}

enum _ContentBlockType { heading, paragraph, bullet }

class _ContentBlockView extends StatelessWidget {
  final _ContentBlock block;
  const _ContentBlockView({required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case _ContentBlockType.heading:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w900,
            color: AppTheme.ink,
          ),
        );
      case _ContentBlockType.paragraph:
        return Text(
          block.text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        );
      case _ContentBlockType.bullet:
        final String title = block.bulletTitle ?? '';
        final String body = block.bulletBody ?? '';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                '•',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.2,
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: title.isNotEmpty ? '$title: ' : '',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: body),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _BulletParts {
  final String title;
  final String body;
  const _BulletParts(this.title, this.body);
}
