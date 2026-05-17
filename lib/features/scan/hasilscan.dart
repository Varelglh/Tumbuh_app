import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/recipes_api.dart';
import 'package:tumbuh_app/features/resep/detailresep.dart';

class HasilScanPage extends StatefulWidget {
  final String? ingredientName;
  final Map<String, dynamic>? ingredient;

  const HasilScanPage({super.key, this.ingredientName, this.ingredient});

  @override
  State<HasilScanPage> createState() => _HasilScanPageState();
}

class _HasilScanPageState extends State<HasilScanPage> {
  final RecipesApi _recipesApi = RecipesApi();

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _all = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filtered = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  String get _ingredientName {
    final s = (widget.ingredientName ?? '').trim();
    if (s.isNotEmpty) return s;
    final fromMap = (widget.ingredient?['name'] ?? '').toString().trim();
    return fromMap;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cream,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String ing = _ingredientName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ing.isEmpty ? 'Rekomendasi Resep' : 'Rekomendasi Resep $ing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                if (ing.isNotEmpty)
                  Text(
                    'Berdasarkan bahan terdeteksi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(0.55),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filtered.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            _error ?? 'Resep tidak ditemukan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _ingredientName.isEmpty
                ? 'Coba tekan tombol di atas untuk memuat resep.'
                : 'Coba tekan tombol di atas untuk memuat resep berbahan "$_ingredientName".',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _filtered.length,
      itemBuilder: (context, index) => _buildRecipeCard(_filtered[index]),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> r) {
    final String title = (r['title'] ?? r['name'] ?? '').toString().trim();
    final String subtitle = (r['subtitle'] ?? r['category'] ?? '')
        .toString()
        .trim();
    final int cookingTime = _toInt(r['cookingTime']) ?? 0;
    final int caloriesValue = _toInt(r['caloriesValue']) ?? 0;
    final List<String> tags = _tagsFromRecipe(r);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailResepPage(recipe: r)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.network(
                  (r['imageUrl'] ?? '').toString(),
                  width: 120,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title.isNotEmpty ? title : 'Resep',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle.isNotEmpty ? subtitle : '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badge(
                            Icons.timer_outlined,
                            cookingTime > 0 ? '$cookingTime Menit' : '-',
                            Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          _badge(
                            Icons.bolt,
                            caloriesValue > 0 ? '$caloriesValue kal' : '-',
                            AppTheme.brandGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (tags.isNotEmpty)
                        Row(children: tags.take(2).map(_miniTag).toList()),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
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

  Future<void> _loadRecipes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _recipesApi.fetchRecipes();
      if (!mounted) return;

      setState(() {
        _all = items;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat resep.';
        _all = <Map<String, dynamic>>[];
        _filtered = <Map<String, dynamic>>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    Iterable<Map<String, dynamic>> items = _all;

    // 1) Filter sesuai bahan terdeteksi (kalau ada)
    final ing = _norm(_ingredientName);
    if (ing.isNotEmpty) {
      items = items.where((r) {
        final String ingredients = (r['ingredients'] ?? '').toString();
        final String name = (r['name'] ?? r['title'] ?? '').toString();
        final String label = (r['label'] ?? '').toString();
        final String category = (r['category'] ?? r['subtitle'] ?? '')
            .toString();

        final blob = _norm('$ingredients $name $label $category');
        return blob.contains(ing);
      });
    }

    _filtered = items.toList(growable: false);
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static List<String> _tagsFromRecipe(Map<String, dynamic> r) {
    final List<String> out = <String>[];

    final dynamic rawLabel = r['label'];
    final Iterable<String> labelItems;
    if (rawLabel is List) {
      labelItems = rawLabel.map((e) => (e ?? '').toString());
    } else {
      String s = (rawLabel ?? '').toString().trim();
      // When backend sends list-ish string, e.g. "[A, B]".
      if (s.startsWith('[') && s.endsWith(']') && s.length >= 2) {
        s = s.substring(1, s.length - 1);
      }
      labelItems = s.split(RegExp(r'[,/|]'));
    }

    final cleaned = labelItems
        .map((e) => e.trim())
        .map((e) {
          var t = e;
          if (t.startsWith('[')) t = t.substring(1);
          if (t.endsWith(']')) t = t.substring(0, t.length - 1);
          if ((t.startsWith('"') && t.endsWith('"')) ||
              (t.startsWith("'") && t.endsWith("'"))) {
            t = t.substring(1, t.length - 1);
          }
          return t.trim();
        })
        .where((e) => e.isNotEmpty);

    out.addAll(cleaned);

    final bool popular =
        (r['iconStatus'] == true) ||
        (r['iconStatus']?.toString() == '1') ||
        (r['iconStatus']?.toString().toLowerCase() == 'true');
    if (popular) out.insert(0, 'Populer');

    // Dedup
    final seen = <String>{};
    return out.where((t) => seen.add(_norm(t))).toList(growable: false);
  }
}
