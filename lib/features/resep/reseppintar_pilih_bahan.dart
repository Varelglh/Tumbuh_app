import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/ingredients_api.dart';
import 'reseppintar_pilih_kriteria.dart'; // Import halaman tujuan selanjutnya

class PilihBahanPage extends StatefulWidget {
  const PilihBahanPage({super.key});

  @override
  State<PilihBahanPage> createState() => _PilihBahanPageState();
}

class _PilihBahanPageState extends State<PilihBahanPage> {
  final IngredientsApi _ingredientsApi = IngredientsApi();

  List<String> _ingredients = <String>[];
  bool _loading = false;
  String? _error;

  int? _selectedIndex;

  static const List<String> _allowedIngredients = <String>[
    'Ikan',
    'Telur',
    'Ayam',
    'Tempe',
    'Kentang',
    'Jagung',
    'Terong',
    'Talas',
    'Tahu',
    'Bayam',
    'Kangkung',
    'Sosin',
    'Cabai Rawit',
    'Sawi Hijau',
    'Tomat',
  ];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _ingredientsApi.fetchIngredientNames();
      if (!mounted) return;
      setState(() {
        _ingredients = _applyAllowedFilter(items);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ingredients = List<String>.from(_allowedIngredients);
        _error = 'Gagal memuat bahan.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  static List<String> _applyAllowedFilter(List<String> apiItems) {
    final Set<String> apiKeys = <String>{for (final s in apiItems) _norm(s)};

    final List<String> filtered = <String>[];
    for (final String allowed in _allowedIngredients) {
      if (apiKeys.contains(_norm(allowed))) {
        filtered.add(allowed);
      }
    }

    // Kalau API kosong/beda format, tetap tampilkan daftar yang diminta.
    return filtered.isNotEmpty
        ? filtered
        : List<String>.from(_allowedIngredients);
  }

  static String _norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // Tomat Back Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 30,
                    color: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Logo dan Teks Judul
            Center(
              child: Column(
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
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Bahan pangan kamu :',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5D5D),
                    ),
                  ),
                  const Text(
                    '(Centang Bahan Yang Tersedia)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Grid Bahan Makanan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _ingredients.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error ?? 'Belum ada bahan.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, index) {
                          final name = _ingredients[index];
                          final isSelected = _selectedIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = isSelected ? null : index;
                              });
                            },
                            child: _buildIngredientCard(
                              name,
                              _emojiForIngredient(name),
                              isSelected,
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Tombol Lanjutkan
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton(
                onPressed: () {
                  final String? selectedIngredient = (_selectedIndex == null)
                      ? null
                      : _ingredients[_selectedIndex!];

                  // Navigasi ke halaman Pilih Kriteria (4-C)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PilihKriteriaPage(
                        selectedIngredient: selectedIngredient,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Lanjutkan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  static String _emojiForIngredient(String name) {
    final String key = _norm(name);
    if (key.isEmpty) return '🥗';

    const Map<String, String> iconByKey = <String, String>{
      'ikan': '🐟',
      'telur': '🥚',
      'ayam': '🍗',
      'tempe': '🫘',
      'kentang': '🥔',
      'jagung': '🌽',
      'terong': '🍆',
      'talas': '🍠',
      'tahu': '⬜',
      'bayam': '🥬',
      'kangkung': '🥬',
      'sosin': '🥬',
      'cabai rawit': '🌶️',
      'sawi hijau': '🥬',
      'tomat': '🍅',
    };

    return iconByKey[key] ?? '🥗';
  }

  Widget _buildIngredientCard(String name, String icon, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icon Centang (Muncul hanya jika dipilih)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: isSelected ? AppTheme.brandGreen : Colors.transparent,
              ),
            ),
          ),
          // Isi Card
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F4E8),
                    shape: BoxShape.circle,
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D5D5D),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
