import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/recipes_api.dart';
import 'detailresep.dart';

class HasilResepPage extends StatefulWidget {
  final String? selectedIngredient;
  final String? selectedCriteria;
  const HasilResepPage({
    super.key,
    this.selectedIngredient,
    this.selectedCriteria,
  });

  @override
  State<HasilResepPage> createState() => _HasilResepPageState();
}

class _HasilResepPageState extends State<HasilResepPage> {
  final RecipesApi _recipesApi = RecipesApi();

  List<Map<String, dynamic>> _all = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filtered = <Map<String, dynamic>>[];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
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
        _all = <Map<String, dynamic>>[];
        _filtered = <Map<String, dynamic>>[];
        _error = 'Gagal memuat resep.';
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
    final String ingredient = (widget.selectedIngredient ?? '').trim();
    final String criteria = (widget.selectedCriteria ?? '').trim();

    Iterable<Map<String, dynamic>> items = _all;

    if (ingredient.isNotEmpty) {
      final String ingredientKey = _norm(ingredient);
      items = items.where((m) => _matchesIngredient(m, ingredientKey));
    }

    if (criteria.isNotEmpty) {
      items = items.where((m) => _matchesCriteria(m, criteria));
    }

    _filtered = items.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Material widget wajib ada agar InkWell/GestureDetector tidak error
    return Material(
      color: AppTheme.cream,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error ?? 'Resep tidak ditemukan.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) =>
                          _buildRecipeCard(_filtered[index]),
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
            'Hasil Resep Pintar',
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
    final String title = (r['name'] ?? r['title'] ?? '').toString();
    final String subtitle = (r['category'] ?? r['subtitle'] ?? '').toString();

    final int cookingTime = _toInt(r['cookingTime']) ?? 0;
    final String durationText = cookingTime > 0 ? '$cookingTime Menit' : '-';

    final int caloriesValue = _toInt(r['caloriesValue']) ?? 0;
    final String caloriesText = caloriesValue > 0 ? '$caloriesValue kal' : '-';

    final List<String> tags = _extractTags(r);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailResepPage(recipe: r)),
        ),
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
                  // Mengatasi error 404 agar tidak muncul teks merah/garis kuning
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
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
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
                            durationText,
                            Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          _badge(Icons.bolt, caloriesText, AppTheme.brandGreen),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (tags.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: tags
                                .map((t) => _miniTag(t))
                                .toList(growable: false),
                          ),
                        ),
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

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static String _cleanLabelToken(String input) {
    String s = input.trim();
    if (s.isEmpty) return s;

    // Handle common cases like: ["Tinggi Protein", "Rendah Kalori"] or [Tinggi Protein]
    s = s.replaceAll(RegExp(r'[\[\]\{\}"]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static bool _matchesIngredient(Map<String, dynamic> r, String ingredientKey) {
    final String ingredientsRaw = (r['ingredients'] ?? r['ingredient'] ?? '')
        .toString();
    final String ingredientsKey = _norm(ingredientsRaw);
    if (ingredientsKey.isEmpty) return false;

    // Match "cabai rawit" etc.
    return ingredientsKey.contains(ingredientKey);
  }

  static bool _matchesCriteria(Map<String, dynamic> r, String criteria) {
    final String c = criteria.trim();
    if (c.isEmpty) return true;

    final String cKey = _norm(c).replaceAll('+', '').trim();

    final String labelKey = _norm(
      _cleanLabelToken((r['label'] ?? '').toString()),
    );
    final String categoryKey = _norm((r['category'] ?? '').toString());
    final int cookingTime = _toInt(r['cookingTime']) ?? 0;
    final int caloriesValue = _toInt(r['caloriesValue']) ?? 0;

    if (cKey.isNotEmpty && labelKey.contains(cKey)) return true;

    bool hasKeyword(String k) {
      final String kk = _norm(k);
      if (kk.isEmpty) return false;
      return labelKey.contains(kk) || categoryKey.contains(kk);
    }

    if (cKey.contains('vegetarian')) {
      return hasKeyword('vegetarian');
    }

    if (cKey.contains('vitamin')) {
      return hasKeyword('vitamin');
    }

    if (cKey.contains('protein')) {
      return hasKeyword('protein');
    }

    if (cKey.contains('lemak')) {
      if (hasKeyword('lemak sedang') || hasKeyword('medium fat')) return true;
      if (hasKeyword('sedang lemak') || hasKeyword('lemak medium')) return true;
      return hasKeyword('lemak');
    }

    if (cKey.contains('rendah kalori') || cKey.contains('kalori')) {
      if (hasKeyword('rendah kalori') || hasKeyword('low calorie')) return true;
      return caloriesValue > 0 && caloriesValue <= 250;
    }

    if (cKey.contains('cepat') || cKey.contains('quick')) {
      if (hasKeyword('cepat') || hasKeyword('quick')) return true;
      return cookingTime > 0 && cookingTime <= 20;
    }

    // Fallback: strict contains
    return hasKeyword(cKey);
  }

  static List<String> _extractTags(Map<String, dynamic> r) {
    final String label = _cleanLabelToken((r['label'] ?? '').toString());

    final List<String> raw = label
        .split(RegExp(r'[,/|]'))
        .map(_cleanLabelToken)
        .where((e) => e.isNotEmpty)
        .toList();

    final List<String> out = <String>[];
    final Set<String> seen = <String>{};
    for (final s in raw) {
      final k = _norm(s);
      if (k.isEmpty || seen.contains(k)) continue;
      seen.add(k);
      out.add(s);
      if (out.length >= 2) break;
    }

    return out;
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
    final String safeText = _cleanLabelToken(text);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        safeText,
        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
      ),
    );
  }
}
