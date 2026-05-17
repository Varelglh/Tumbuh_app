part of '../detailresep.dart';

class _CookingStepsSection extends StatelessWidget {
  final Map<String, dynamic> r;

  const _CookingStepsSection({required this.r});

  @override
  Widget build(BuildContext context) {
    final String description = (r['description'] ?? '').toString();
    final String steps =
        ((r['instructions'] ?? '').toString().trim().isNotEmpty)
        ? (r['instructions'] ?? '').toString()
        : (r['recipeDetails'] ?? '').toString();
    final String videoUrl = (r['videoUrl'] ?? '').toString();

    final bool hasVideo = videoUrl.trim().isNotEmpty;
    final bool hasDescription = description.trim().isNotEmpty;
    final String stepsParagraph = steps.trim();
    final bool stepsLookLikeList = _looksLikeStepList(stepsParagraph);
    final List<String> stepItems = stepsLookLikeList
        ? _parseSteps(stepsParagraph)
        : const <String>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cara Memasak Resep',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            if (hasVideo) ...[
              _VideoPreview(videoUrl: videoUrl),
              const SizedBox(height: 10),
              _VideoSource(videoUrl: videoUrl),
            ],
            if (hasVideo && (hasDescription || stepsParagraph.isNotEmpty))
              const SizedBox(height: 14),
            if (hasDescription) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  description.trim(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.75),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (hasDescription &&
                (stepItems.isNotEmpty || stepsParagraph.isNotEmpty))
              const SizedBox(height: 14),
            if (stepItems.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List<Widget>.generate(stepItems.length, (i) {
                  final stepText = stepItems[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == stepItems.length - 1 ? 0 : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppTheme.brandGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandGreenDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stepText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.55,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            if (stepItems.isEmpty && stepsParagraph.isNotEmpty)
              Text(
                stepsParagraph,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final String videoUrl;

  const _VideoPreview({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final String url = videoUrl.trim();
    final String? ytId = url.isNotEmpty ? _extractYoutubeId(url) : null;
    final String? thumb = (ytId != null) ? _youtubeThumbUrl(ytId) : null;

    Future<void> open() async {
      final Uri? uri = Uri.tryParse(url);
      if (uri == null) return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null)
                Image.network(
                  thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade300),
                )
              else
                Container(color: Colors.grey.shade300),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.45),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black87,
                    size: 34,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoSource extends StatelessWidget {
  final String videoUrl;

  const _VideoSource({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final String url = videoUrl.trim();
    final String? ytId = url.isNotEmpty ? _extractYoutubeId(url) : null;

    if (ytId == null) {
      final host = Uri.tryParse(url)?.host.trim();

      Future<void> open() async {
        final Uri? uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      return Row(
        children: [
          const Icon(Icons.link, size: 16, color: AppTheme.muted),
          const SizedBox(width: 6),
          const Text(
            'Sumber:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: open,
              child: Text(
                host != null && host.isNotEmpty ? host : url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandGreenDark,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return FutureBuilder<_YoutubeOembed?>(
      future: _youtubeOembed(url),
      builder: (context, snap) {
        final meta = snap.data;
        final String channelName = (meta?.authorName ?? '').trim();
        final String channelUrl = (meta?.authorUrl ?? '').trim();

        Future<void> openChannel() async {
          if (channelUrl.isEmpty) return;
          final Uri? uri = Uri.tryParse(channelUrl);
          if (uri == null) return;
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }

        return Row(
          children: [
            const Icon(Icons.link, size: 16, color: AppTheme.muted),
            const SizedBox(width: 6),
            const Text(
              'Sumber:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: channelUrl.isNotEmpty ? openChannel : null,
                child: Text(
                  channelName.isNotEmpty ? channelName : 'YouTube',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: channelUrl.isNotEmpty
                        ? AppTheme.brandGreenDark
                        : AppTheme.muted,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
