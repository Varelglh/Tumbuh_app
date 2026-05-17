import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_header.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_search_field.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/utils/auth_ui.dart';
import 'package:tumbuh_app/features/resep/detailresep.dart';
import 'package:tumbuh_app/features/resep/reseppintar_pilih_bahan.dart';
import 'package:tumbuh_app/core/services/recipes_api.dart';

class ResepPage extends StatefulWidget {
  const ResepPage({super.key});

  @override
  State<ResepPage> createState() => _ResepPageState();
}

class _ResepPageState extends State<ResepPage> {
  final RecipesApi _recipesApi = RecipesApi();

  static const String _fallbackImageUrl =
      'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?auto=format&fit=crop&w=1200&q=80';

  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecipes,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildBanner(),
                const SizedBox(height: 16),
                _buildSearch(),
                const SizedBox(height: 12),
                _buildFilterPills(),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        _error ?? 'Belum ada resep.',
                        style: const TextStyle(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    itemCount: _filtered.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (_, i) => _buildRecipeCard(_filtered[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- STATE UNTUK FILTER ---
  String _selectedFilter = 'Terbaru';
  final List<String> _categories = [
    'Semua',
    'Terbaru',
    'Minuman',
    'Camilan',
    'Masakan',
  ];
  // ---------------------------

  List<Map<String, dynamic>> _all = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _filtered = [];
  String _query = '';

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

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null; 
    return DateTime.tryParse(value.toString());
  }

  void _applyFilters() {
    final q = _query.trim().toLowerCase();
    Iterable<Map<String, dynamic>> items = _all;

    if (_selectedFilter != 'Terbaru' && _selectedFilter != 'Semua') {
      final selected = _norm(_selectedFilter);
      if (selected.contains('populer')) {
        items = items.where((m) {
          final dynamic raw = m['iconStatus'];
          if (raw == true) return true;
          final String s = raw is List
              ? raw.map((e) => e.toString()).join(' ').toLowerCase()
              : (raw ?? '').toString().toLowerCase();
          return s.contains('populer') || s == 'true' || s == '1';
        });
      } else {
        items = items.where((m) {
          final String cat = _norm((m['category'] ?? '').toString());
          if (selected.contains('masakan')) {
            // Banyak API pakai kategori "Makan Siang/Malam".
            return cat.contains('masakan') || cat.contains('makan');
          }
          return cat.contains(selected);
        });
      }
    }

    if (q.isNotEmpty) {
      items = items.where((m) {
        final String name = (m['name'] ?? '').toString().toLowerCase();
        final String label = (m['label'] ?? '').toString().toLowerCase();
        final String category = (m['category'] ?? '').toString().toLowerCase();
        return name.contains(q) || label.contains(q) || category.contains(q);
      });
    }

    final List<Map<String, dynamic>> list = items.toList();
    if (_selectedFilter == 'Terbaru') {
      list.sort((a, b) {
        final da = _tryParseDate(a['createdAt']);
        final db = _tryParseDate(b['createdAt']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    }

    _filtered = list;
  }

  void _search(String q) {
    setState(() {
      _query = q;
      _applyFilters();
    });
  }

  // --- WIDGET BARU: FILTER PILL ---
  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final selected = _selectedFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) => setState(() {
                _selectedFilter = cat;
                _applyFilters();
              }),
              selectedColor: AppTheme.brandGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.brandGreenDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<String>(
      future: AuthStorage().getDisplayName(),
      builder: (context, snap) {
        final name = (snap.data ?? 'Pengguna').trim();
        return TumbuhHeader(
          title: 'Halo, ${name.isNotEmpty ? name : 'Pengguna'}',
          subtitle: 'Mau masak apa hari ini ?',
          onProfileTap: () => showLogoutDialog(context),
          trailing: const Icon(
            Icons.wb_sunny_outlined,
            color: Colors.amber,
            size: 28,
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.brandGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🌞', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Resep Pintar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.brandGreenDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bingung mau masak apa hari ini?',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppTheme.ink,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sesuaikan masakan sehatmu dengan bahan dan kebutuhan yang kamu inginkan.',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PilihBahanPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.search, size: 18, color: Colors.white),
                label: const Text(
                  'Klik disini',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TumbuhSearchField(
      hintText: 'Cari resep… (Ayam, Sayur, Talas)',
      onChanged: _search,
      borderRadius: BorderRadius.circular(24),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> r) {
    final String rawImageUrl = (r['imageUrl'] ?? '').toString().trim();
    final String imageUrl = rawImageUrl.isNotEmpty
        ? rawImageUrl
        : _fallbackImageUrl;
    final String name = (r['name'] ?? r['title'] ?? '').toString().trim();
    final int cookingTime = _toInt(r['cookingTime']);
    final int calories = _toInt(r['caloriesValue']);
    final List<String> labels = _firstTwoLabels(r['label']);
    final String firstLabel = labels.isNotEmpty ? labels[0] : '';
    final String secondLabel = labels.length > 1 ? labels[1] : '';
    final String category = _cleanTag(
      (r['category'] ?? r['subtitle'] ?? '').toString(),
    );
    final String categoryLikeText = firstLabel.isNotEmpty
        ? firstLabel
        : category;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailResepPage(recipe: r)),
          );
        },
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
                        name.isNotEmpty ? name : 'Resep',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (categoryLikeText.isNotEmpty)
                        Text(
                          categoryLikeText,
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
                          _badge(
                            Icons.timer_outlined,
                            cookingTime > 0 ? '$cookingTime Menit' : '-',
                            Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          _badge(
                            Icons.bolt,
                            calories > 0 ? '$calories kal' : '-',
                            AppTheme.brandGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (firstLabel.isNotEmpty) _miniTag(firstLabel),
                          if (secondLabel.isNotEmpty) _miniTag(secondLabel),
                        ],
                      ),
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

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString();
    final m = RegExp(r'(\d+)').firstMatch(s);
    if (m == null) return 0;
    return int.tryParse(m.group(1) ?? '') ?? 0;
  }

  static String _cleanTag(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';

    final lower = s.toLowerCase();
    if (lower == '[]' || lower == 'null' || lower == '-' || lower == 'nan') {
      return '';
    }

    s = s.replaceAll(RegExp("^[\\[\\(\\{\\s\"']+"), '');
    s = s.replaceAll(RegExp("[\\]\\)\\}\\s\"']+\$"), '');
    return s.trim();
  }

  static List<String> _firstTwoLabels(dynamic raw) {
    if (raw == null) return const <String>[];

    final List<String> parts = <String>[];

    if (raw is List) {
      for (final e in raw) {
        final s = _cleanTag((e ?? '').toString());
        if (s.isEmpty) continue;
        if (parts.contains(s)) continue;
        parts.add(s);
        if (parts.length >= 2) break;
      }
      return parts;
    }

    final cleaned = _cleanTag(raw.toString());
    if (cleaned.isEmpty) return const <String>[];

    final split = cleaned.split(RegExp(r'[|,]'));
    for (final p in split) {
      final s = _cleanTag(p);
      if (s.isEmpty) continue;
      if (parts.contains(s)) continue;
      parts.add(s);
      if (parts.length >= 2) break;
    }

    return parts;
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
