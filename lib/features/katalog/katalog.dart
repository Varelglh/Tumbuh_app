import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/services/products_api.dart';
import 'package:tumbuh_app/core/utils/auth_ui.dart';
import 'package:tumbuh_app/core/utils/products_refresh.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_header.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_search_field.dart';

import 'createkatalog.dart';
import 'detailkatalog.dart';
import 'produk_saya.dart';

class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});

  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

class _KatalogPageState extends State<KatalogPage> {
  final ProductsApi _productsApi = ProductsApi();

  List<Map<String, dynamic>> _products = <Map<String, dynamic>>[];
  bool _loading = false;
  String? _error;

  String _displayName = '';
  String _query = '';
  int _selectedChip = 1;
  final List<String> _chips = <String>[
    'Terbaru',
    'Populer',
    'Camilan',
    'Masakan',
    'Bahan Mentah',
  ];

  @override
  void initState() {
    super.initState();
    ProductsRefresh.counter.addListener(_onProductsChanged);
    _loadProducts();
    _loadDisplayName();
  }

  @override
  void dispose() {
    ProductsRefresh.counter.removeListener(_onProductsChanged);
    super.dispose();
  }

  void _onProductsChanged() {
    _loadProducts();
  }

  Future<void> _loadDisplayName() async {
    try {
      final String name = await AuthStorage().getDisplayName();
      if (!mounted) return;
      setState(() {
        _displayName = name.trim();
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final List<Map<String, dynamic>> items = await _productsApi
          .fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = items;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat produk.';
        _products = <Map<String, dynamic>>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  static String _norm(String v) {
    return v
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  List<Map<String, dynamic>> get _filtered {
    final String q = _query.trim().toLowerCase();

    // start with a copy so we can sort safely
    List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
      _products,
    );

    if (q.isNotEmpty) {
      items = items.where((m) {
        final String title = (m['title'] ?? m['name'] ?? '')
            .toString()
            .toLowerCase();
        final String author = (m['author'] ?? m['label'] ?? '')
            .toString()
            .toLowerCase();
        return title.contains(q) || author.contains(q);
      }).toList();
    }

    final String selected =
        (_selectedChip >= 0 && _selectedChip < _chips.length)
        ? _chips[_selectedChip]
        : _chips.first;

    if (selected == 'Terbaru') {
      items.sort((a, b) {
        final String ar = (a['createdAt'] ?? '').toString();
        final String br = (b['createdAt'] ?? '').toString();
        final DateTime? ad = DateTime.tryParse(ar);
        final DateTime? bd = DateTime.tryParse(br);
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
      return items;
    }

    if (selected == 'Populer') {
      items.sort((a, b) {
        final double ar = _ratingValue(a['rating']);
        final double br = _ratingValue(b['rating']);
        if (br != ar) return br.compareTo(ar);

        final int ac = _reviewsValue(a['reviews'] ?? a['reviewCount']);
        final int bc = _reviewsValue(b['reviews'] ?? b['reviewCount']);
        return bc.compareTo(ac);
      });
      return items;
    }

    // Category filter
    final String target = _norm(selected);
    return items.where((m) {
      final String cat = _norm((m['category'] ?? '').toString());
      return cat == target;
    }).toList();
  }

  static String _labelText(Map<String, dynamic> p) {
    final String s = (p['label'] ?? p['author'] ?? p['category'] ?? '')
        .toString()
        .trim();
    return s.isEmpty ? '-' : s;
  }

  static double _ratingValue(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  static int _reviewsValue(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  void _goToDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailKatalogPage(product: product)),
    );
  }

  Widget _produkSayaButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProdukSayaPage()),
        );
        // Kembali dari Produk Saya (mungkin habis edit/hapus)
        await _loadProducts();
      },
      icon: const Icon(Icons.storefront, size: 18),
      label: const Text(
        'Produk Saya',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.brandGreen,
        side: const BorderSide(color: AppTheme.brandGreen),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = _filtered;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TumbuhHeader(
                      title:
                          'Halo, ${_displayName.isNotEmpty ? _displayName : 'Pengguna'}',
                      subtitle: 'Mau Belanja apa hari ini ?',
                      onProfileTap: () => showLogoutDialog(context),
                      trailing: InkWell(
                        onTap: () async {
                          final bool? created = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateKatalogPage(),
                            ),
                          );
                          if (created == true) {
                            await _loadProducts();
                          }
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brandGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_circle,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tambah',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    'Produk',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TumbuhSearchField(
                      hintText: 'Cari Produk....',
                      onChanged: (v) => setState(() => _query = v),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_chips.length, (i) {
                          final bool selected = i == _selectedChip;
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _produkSayaButton(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error ?? 'Belum ada produk.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 260,
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final Map<String, dynamic> p = items[i];
                    final String title = (p['title'] ?? p['name'] ?? '')
                        .toString();
                    final String label = _labelText(p);
                    final String price = (p['price'] ?? 'Rp.0').toString();
                    final double rating = _ratingValue(p['rating']);
                    final int reviews = _reviewsValue(
                      p['reviews'] ?? p['reviewCount'],
                    );
                    final String location = (p['location'] ?? '-').toString();
                    final String imageUrl = (p['image'] ?? p['imageUrl'] ?? '')
                        .toString();

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _goToDetail(p),
                      child: Card(
                        elevation: 2,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14),
                              ),
                              child: Image.network(
                                imageUrl,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) {
                                  return Container(
                                    height: 100,
                                    color: Colors.black12,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'oleh $label',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      price,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.brandGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '($reviews)',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            location,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 30,
                                      child: ElevatedButton(
                                        onPressed: () => _goToDetail(p),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Text(
                                          'Pesan',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: items.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
