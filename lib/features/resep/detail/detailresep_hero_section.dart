part of '../detailresep.dart';

class _HeroImageSection extends StatelessWidget {
  final Map<String, dynamic> r;
  final VoidCallback onLike;
  final bool isLiked;
  final bool isBusy;

  const _HeroImageSection({
    required this.r,
    required this.onLike,
    required this.isLiked,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = _pickFirstNonEmpty([
      r['imageUrl'],
      _fallbackImageUrl,
    ]);
    final String name = _pickFirstNonEmpty([r['name'], r['title']]);

    final List<String> labels = _extractLabels(r);

    final String category = _pickFirstNonEmpty([r['category'], r['subtitle']]);
    final bool isPopular =
        (r['iconStatus'] == true) ||
        ((r['iconStatus'] ?? '').toString().toLowerCase() == 'true') ||
        ((r['iconStatus'] ?? '').toString() == '1');
    final int cookingTime = _tryParseInt(r['cookingTime']) > 0
        ? _tryParseInt(r['cookingTime'])
        : _extractFirstNumber(r['duration']);
    final int calories = _tryParseInt(r['caloriesValue']) > 0
        ? _tryParseInt(r['caloriesValue'])
        : _extractFirstNumber(r['calories']);

    final double topInset = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // Main Image
        SizedBox(
          height: 320,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Image.network(_fallbackImageUrl, fit: BoxFit.cover),
          ),
        ),

        // Gradient Overlay
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Back Button
        Positioned(
          top: topInset + 12,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ),

        // Recipe Info Overlay
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name.isNotEmpty ? name : 'Detail Resep',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: isBusy ? null : onLike,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isLiked
                            ? Colors.red
                            : Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.white : Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                () {
                  if (category.isNotEmpty) return category;
                  if (labels.isNotEmpty) return labels.first;
                  return isPopular ? 'Populer' : '';
                }(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cookingTime > 0 ? '$cookingTime Menit' : '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '|',
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          calories > 0 ? '$calories kal' : '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (category.isNotEmpty)
                    _Badge(label: category, color: Colors.yellow.shade700),
                  ...labels.map(
                    (e) => _Badge(label: e, color: Colors.yellow.shade700),
                  ),
                  if (isPopular)
                    _Badge(label: 'Populer', color: Colors.yellow.shade700),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
