import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/recipes_api.dart';
import 'package:tumbuh_app/features/resep/detailresep.dart';

class ResepDisukaiPage extends StatefulWidget {
  const ResepDisukaiPage({super.key});

  @override
  State<ResepDisukaiPage> createState() => _ResepDisukaiPageState();
}

class _ResepDisukaiPageState extends State<ResepDisukaiPage> {
  final RecipesApi _recipesApi = RecipesApi();
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _loading = false;
  String? _error;

  static const String _fallbackImageUrl =
      'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?auto=format&fit=crop&w=1200&q=80';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _recipesApi.fetchLikedRecipesMe();
      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat resep disukai.';
        _items = <Map<String, dynamic>>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is List) {
      return raw
          .map((e) => (e ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return const <String>[];

    // Handle formats like: [A, B] or A, B or A|B
    final cleaned = s
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '');

    final parts = cleaned.split(RegExp(r'[|,]'));
    return parts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static String _durationText(dynamic cookingTime) {
    final int? v = cookingTime is int
        ? cookingTime
        : int.tryParse((cookingTime ?? '').toString());
    if (v == null || v <= 0) return '-';
    return '$v Menit';
  }

  static String _caloriesText(dynamic caloriesValue) {
    final int? v = caloriesValue is int
        ? caloriesValue
        : int.tryParse((caloriesValue ?? '').toString());
    if (v == null || v <= 0) return '-';
    return '$v kal';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cream,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error ?? 'Belum ada resep yang disukai.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _items.length,
                      itemBuilder: (context, index) =>
                          _buildRecipeCard(_items[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Resep Disukai',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> r) {
    final String title = (r['name'] ?? r['title'] ?? '').toString().trim();
    final List<String> labels = (() {
      final raw = _parseTags(r['label']);
      final List<String> unique = <String>[];
      for (final t in raw) {
        final s = t.trim();
        if (s.isEmpty) continue;
        if (unique.contains(s)) continue;
        unique.add(s);
        if (unique.length >= 2) break;
      }
      return unique;
    })();
    final String firstLabel = labels.isNotEmpty ? labels.first : '';
    final String duration = _durationText(r['cookingTime']);
    final String calories = _caloriesText(r['caloriesValue']);

    final String rawImageUrl = (r['imageUrl'] ?? '').toString().trim();
    final String imageUrl = rawImageUrl.isNotEmpty
        ? rawImageUrl
        : _fallbackImageUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetailResepPage(recipe: r, initiallyLiked: true),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 118,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: Image.network(
                  imageUrl,
                  width: 110,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 110,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title.isNotEmpty ? title : 'Resep',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (firstLabel.isNotEmpty)
                        Text(
                          firstLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.muted,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badge(Icons.timer_outlined, duration, Colors.orange),
                          const SizedBox(width: 6),
                          _badge(Icons.bolt, calories, AppTheme.brandGreen),
                        ],
                      ),
                      if (labels.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _miniTag(labels[0]),
                            if (labels.length > 1) _miniTag(labels[1]),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
      ),
    );
  }
}
