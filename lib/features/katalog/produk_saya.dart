import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/services/products_api.dart';
import 'package:tumbuh_app/core/utils/app_notify.dart';
import 'package:tumbuh_app/core/utils/products_refresh.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_search_field.dart';

import 'createkatalog.dart';
import 'detailkatalog.dart';

class ProdukSayaPage extends StatefulWidget {
  const ProdukSayaPage({super.key});

  @override
  State<ProdukSayaPage> createState() => _ProdukSayaPageState();
}

class _ProdukSayaPageState extends State<ProdukSayaPage> {
  final ProductsApi _productsApi = ProductsApi();

  List<Map<String, dynamic>> _products = <Map<String, dynamic>>[];
  bool _loading = false;
  String? _error;

  String _query = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    ProductsRefresh.counter.addListener(_onProductsChanged);
    _load();
  }

  @override
  void dispose() {
    ProductsRefresh.counter.removeListener(_onProductsChanged);
    super.dispose();
  }

  void _onProductsChanged() {
    if (!mounted) return;
    if (_loading) return;
    _load();
  }

  static String _normalize(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _sellerText(Map<String, dynamic> p) {
    final dynamic seller = p['seller'] ?? p['user'] ?? p['owner'];
    if (seller is Map) {
      final dynamic name =
          seller['username'] ?? seller['userName'] ?? seller['name'];
      final String s = (name ?? '').toString().trim();
      if (s.isNotEmpty) return s;
    }

    final String s = (p['sellerName'] ?? p['userName'] ?? p['username'] ?? '')
        .toString()
        .trim();
    return s;
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final String name = await AuthStorage().getDisplayName();
      final List<Map<String, dynamic>> items = await _productsApi
          .fetchProducts();
      if (!mounted) return;

      setState(() {
        _displayName = name.trim();
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

  List<Map<String, dynamic>> get _mine {
    final String mineKey = _normalize(_displayName);
    if (mineKey.isEmpty || mineKey == _normalize('Pengguna')) {
      return <Map<String, dynamic>>[];
    }

    final String q = _query.trim().toLowerCase();

    Iterable<Map<String, dynamic>> items = _products.where((m) {
      final String seller = _sellerText(m);
      return _normalize(seller) == mineKey;
    });

    if (q.isNotEmpty) {
      items = items.where((m) {
        final String title = (m['title'] ?? m['name'] ?? '').toString();
        final String seller = _sellerText(m);
        return title.toLowerCase().contains(q) ||
            seller.toLowerCase().contains(q);
      });
    }

    return items.toList();
  }

  void _goToDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailKatalogPage(product: product)),
    );
  }

  Future<void> _editProduct(Map<String, dynamic> product) async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateKatalogPage(product: product)),
    );

    if (updated == true) {
      await _load();
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final String id = (product['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          title: Row(
            children: const [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hapus produk?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Produk yang dihapus tidak bisa dikembalikan.',
            style: TextStyle(color: AppTheme.muted, height: 1.25),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brandGreen,
                        side: const BorderSide(color: AppTheme.brandGreen),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final String? token = await AuthStorage().getToken();
    if (token == null || token.trim().isEmpty) {
      if (!mounted) return;
      AppNotify.show(
        context,
        'Sesi login habis. Silakan login ulang.',
        type: AppNotifyType.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      await _productsApi.deleteProduct(id: id, token: token);
      if (!mounted) return;

      AppNotify.show(
        context,
        'Produk berhasil dihapus.',
        type: AppNotifyType.success,
      );

      ProductsRefresh.bump();
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      final int? status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        AppNotify.show(
          context,
          'Sesi login habis. Silakan login ulang.',
          type: AppNotifyType.error,
        );
        return;
      }

      AppNotify.show(
        context,
        'Gagal menghapus produk. Coba lagi.',
        type: AppNotifyType.error,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotify.show(
        context,
        'Gagal menghapus produk. Coba lagi.',
        type: AppNotifyType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = _mine;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Produk Saya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TumbuhSearchField(
                hintText: 'Cari Produk Saya....',
                onChanged: (v) => setState(() => _query = v),
                borderRadius: BorderRadius.circular(28),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error ??
                                (_displayName.trim().isEmpty
                                    ? 'Akun belum terdeteksi.'
                                    : 'Belum ada produk kamu.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 276,
                            ),
                        itemBuilder: (context, i) {
                          final Map<String, dynamic> p = items[i];
                          final String title = (p['title'] ?? p['name'] ?? '')
                              .toString();
                          final String label = _labelText(p);
                          final String price = (p['price'] ?? 'Rp.0')
                              .toString();
                          final double rating = _ratingValue(p['rating']);
                          final int reviews = _reviewsValue(
                            p['reviews'] ??
                                p['reviewCount'] ??
                                p['review_count'],
                          );
                          final String location = (p['location'] ?? '-')
                              .toString();
                          final String imageUrl =
                              (p['image'] ?? p['imageUrl'] ?? '').toString();

                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                  onTap: () => _goToDetail(p),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.network(
                                        'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => _goToDetail(p),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  label,
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
                                                        fontWeight:
                                                            FontWeight.bold,
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _editProduct(p),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: AppTheme.brandGreen,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    32,
                                                  ),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 16,
                                                        color:
                                                            AppTheme.brandGreen,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppTheme
                                                              .brandGreen,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () =>
                                                    _deleteProduct(p),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                      ),
                                                  minimumSize: const Size(
                                                    0,
                                                    32,
                                                  ),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        size: 16,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Hapus',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
