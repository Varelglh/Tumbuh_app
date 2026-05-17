import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/recipes_api.dart';
import 'reseppintar_hasil.dart';

class PilihKriteriaPage extends StatefulWidget {
  final String? selectedIngredient;
  const PilihKriteriaPage({super.key, this.selectedIngredient});

  @override
  State<PilihKriteriaPage> createState() => _PilihKriteriaPageState();
}

class _PilihKriteriaPageState extends State<PilihKriteriaPage> {
  final RecipesApi _recipesApi = RecipesApi();

  static const List<String> _fallbackAllowedLabels = <String>[
    'Tinggi Protein',
    'Lemak Sedang',
    'Rendah Kalori',
  ];

  List<String> _labels = <String>[];
  bool _loading = false;
  String? _error;

  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _recipesApi.fetchRecipes();
      if (!mounted) return;

      final List<String> labels = _pickAllowedLabels(
        _extractUniqueLabels(items),
      );
      setState(() {
        _labels = labels.isNotEmpty
            ? labels
            : List<String>.from(_fallbackAllowedLabels);
        _selectedIndex = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _labels = List<String>.from(_fallbackAllowedLabels);
        _selectedIndex = null;
        _error = 'Gagal memuat kriteria.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  static String _cleanLabelToken(String input) {
    String s = input.trim();
    if (s.isEmpty) return s;

    // Handle common cases like: ["Tinggi Protein", "Lemak Sedang"] or [Tinggi Protein]
    s = s.replaceAll(RegExp(r'[\[\]\{\}"]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _wrapLabelForCard(String label) {
    final String s = label.trim();
    if (s.isEmpty) return s;
    if (s.contains('\n')) return s;

    final List<String> words = s
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (words.length <= 2) return s;

    // Biar rapi: 2 kata di baris pertama, sisanya di baris kedua.
    final String firstLine = words.take(2).join(' ');
    final String secondLine = words.skip(2).join(' ');
    return '$firstLine\n$secondLine';
  }

  static List<String> _extractUniqueLabels(List<Map<String, dynamic>> recipes) {
    final Map<String, String> byKey = <String, String>{};

    for (final r in recipes) {
      final String labelRaw = (r['label'] ?? '').toString();
      if (labelRaw.trim().isEmpty) continue;

      final String sanitized = _cleanLabelToken(labelRaw);

      final parts = sanitized
          .split(RegExp(r'[,/|]'))
          .map(_cleanLabelToken)
          .where((e) => e.isNotEmpty);

      for (final p in parts) {
        final k = _norm(p);
        if (k.isEmpty) continue;
        byKey.putIfAbsent(k, () => p);
      }
    }

    final List<String> labels = byKey.values.toList();
    labels.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return labels;
  }

  static List<String> _pickAllowedLabels(List<String> available) {
    if (available.isEmpty) return <String>[];

    final List<String> out = <String>[];
    final Set<String> used = <String>{};

    String? pick(List<String> variants) {
      for (final v in variants) {
        final vk = _norm(v);
        if (vk.isEmpty) continue;

        // Prefer exact match.
        for (final a in available) {
          final ak = _norm(a);
          if (ak == vk) return a;
        }

        // Then allow "contains" match.
        for (final a in available) {
          final ak = _norm(a);
          if (ak.contains(vk) || vk.contains(ak)) return a;
        }
      }
      return null;
    }

    final String? protein = pick(<String>['tinggi protein', 'protein tinggi']);
    final String? fat = pick(<String>['lemak sedang', 'sedang lemak']);
    final String? lowCal = pick(<String>['rendah kalori', 'low calorie']);

    final List<String?> ordered = <String?>[protein, fat, lowCal];
    for (final s in ordered) {
      final String v = (s ?? '').trim();
      if (v.isEmpty) continue;
      final String k = _norm(v);
      if (k.isEmpty || used.contains(k)) continue;
      used.add(k);
      out.add(v);
    }

    return out;
  }

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  static String _iconForLabel(String label) {
    final String k = _norm(label);
    if (k.isEmpty) return '🏷️';

    if (k.contains('protein')) return '🍗';
    if (k.contains('lemak')) return '🥑';
    if (k.contains('rendah kalori') || k.contains('kalori')) return '📉';

    return '🏷️';
  }

  @override
  Widget build(BuildContext context) {
    // Layout aman di layar kecil: grid bisa discroll + lebar card responsif.
    const double horizontalPadding = 24;
    const double spacing = 14;
    const double runSpacing = 16;

    final double screenWidth = MediaQuery.of(context).size.width;
    // Paksa 3 kolom (sesuai tampilan sebelumnya).
    const int columns = 3;
    final double availableWidth =
        screenWidth - (horizontalPadding * 2) - (spacing * (columns - 1));
    final double cardWidth = (availableWidth / columns).clamp(96, 220);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Header Section
            Column(
              children: [
                Image.asset(
                  'assets/icons/app_icon.png', // Pastikan asset ini ada
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.eco,
                    size: 100,
                    color: AppTheme.brandGreen,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pilih Kriteria Masakan kamu :',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const Text(
                  '(Centang Kriteria Yang Inginkan)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Grid Kriteria (scrollable biar tidak overflow)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _labels.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Center(
                          child: Text(
                            _error ?? 'Belum ada kriteria.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: spacing,
                        runSpacing: runSpacing,
                        alignment: WrapAlignment.center,
                        children: List.generate(_labels.length, (index) {
                          final label = _labels[index];
                          final isSelected = _selectedIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = isSelected ? null : index;
                              });
                            },
                            child: _buildKriteriaCard(
                              label,
                              _iconForLabel(label),
                              isSelected,
                              cardWidth,
                            ),
                          );
                        }),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Cari Resep
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton(
                onPressed: () {
                  final String? selectedCriteria = (_selectedIndex == null)
                      ? null
                      : _labels[_selectedIndex!];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HasilResepPage(
                        selectedIngredient: widget.selectedIngredient,
                        selectedCriteria:
                            (selectedCriteria == null ||
                                selectedCriteria.trim().isEmpty)
                            ? null
                            : selectedCriteria.trim(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Cari Resep',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKriteriaCard(
    String label,
    String icon,
    bool isSelected,
    double width,
  ) {
    final String safeLabel = _cleanLabelToken(label);
    final String displayLabel = _wrapLabelForCard(safeLabel);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Checkbox Icon di pojok kiri atas
          Positioned(
            top: -8,
            left: 4,
            child: Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isSelected ? AppTheme.brandGreen : Colors.grey.shade300,
            ),
          ),
          // Isi Konten
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container bulat untuk Ikon (sesuai gambar)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F4E8),
                    shape: BoxShape.circle,
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 10),
                Text(
                  displayLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D5D5D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
