import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'resep/resep.dart';
import 'resep/detailresep.dart';
import 'scan/scan.dart';
import 'katalog/detailkatalog.dart';
import 'resepdisukai.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/utils/auth_ui.dart';
import 'package:tumbuh_app/core/widgets/tumbuh_header.dart';
import 'package:tumbuh_app/core/services/products_api.dart';
import 'package:tumbuh_app/core/services/recipes_api.dart';
import 'package:tumbuh_app/core/utils/app_notify.dart';
import 'home/panduan_singkat_dialog.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<int>? onNavigateToIndex;
  const HomePage({super.key, this.onNavigateToIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProductsApi _productsApi = ProductsApi();
  final RecipesApi _recipesApi = RecipesApi();

  bool _panduanCheckDone = false;

  final ScrollController _topKatalogScroll = ScrollController();
  final ScrollController _likedRecipesScroll = ScrollController();
  int _topKatalogActiveIndex = 0;
  int _likedRecipesActiveIndex = 0;

  List<Map<String, dynamic>> _topKatalogProducts = <Map<String, dynamic>>[];
  bool _loadingTopKatalog = false;
  String? _topKatalogError;

  List<Map<String, dynamic>> _likedRecipesPreview = <Map<String, dynamic>>[];
  bool _loadingLikedRecipes = false;
  String? _likedRecipesError;

  @override
  void initState() {
    super.initState();
    _loadTopKatalogProducts();
    _loadLikedRecipesPreview();
    _maybeShowPanduanAfterLogin();
  }

  Future<void> _maybeShowPanduanAfterLogin() async {
    if (_panduanCheckDone) return;
    _panduanCheckDone = true;

    bool shouldShow = false;
    try {
      shouldShow = await AuthStorage().consumeShowPanduanAfterLogin();
    } catch (_) {
      // Kalau ada mismatch build saat hot reload/hot restart, jangan bikin crash.
      shouldShow = false;
    }
    if (!shouldShow || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PanduanSingkatDialog.show(context);
    });
  }

  @override
  void dispose() {
    _topKatalogScroll.dispose();
    _likedRecipesScroll.dispose();
    super.dispose();
  }

  Widget _dots({required int count, required int activeIndex}) {
    if (count <= 1) return const SizedBox.shrink();
    final int safeActive = activeIndex.clamp(0, count - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == safeActive;
        return Container(
          width: active ? 8 : 7,
          height: active ? 8 : 7,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.brandGreen
                : AppTheme.brandGreen.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Future<void> _refresh() async {
    await Future.wait([_loadTopKatalogProducts(), _loadLikedRecipesPreview()]);
  }

  Future<void> _loadTopKatalogProducts() async {
    setState(() {
      _loadingTopKatalog = true;
      _topKatalogError = null;
    });
    try {
      final items = await _productsApi.fetchProducts();
      if (!mounted) return;
      setState(() {
        _topKatalogProducts = items.take(4).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _topKatalogError = 'Gagal memuat katalog.';
        _topKatalogProducts = <Map<String, dynamic>>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTopKatalog = false;
        });
      }
    }
  }

  Future<void> _loadLikedRecipesPreview() async {
    setState(() {
      _loadingLikedRecipes = true;
      _likedRecipesError = null;
    });

    try {
      final items = await _recipesApi.fetchLikedRecipesMe();
      if (!mounted) return;
      setState(() {
        _likedRecipesPreview = items.take(4).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      // Jika belum login, cukup tampilkan state kosong (tanpa error keras).
      setState(() {
        final msg = e is StateError ? null : 'Gagal memuat resep disukai.';
        _likedRecipesError = msg;
        _likedRecipesPreview = <Map<String, dynamic>>[];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingLikedRecipes = false;
        });
      }
    }
  }

  static String _labelText(Map<String, dynamic> p) {
    final String s = (p['label'] ?? p['author'] ?? p['category'] ?? '')
        .toString()
        .trim();
    return s.isEmpty ? '-' : s;
  }

  static String _durationText(dynamic cookingTime) {
    final int? v = cookingTime is int
        ? cookingTime
        : int.tryParse((cookingTime ?? '').toString());
    if (v == null || v <= 0) return '-';
    return '$v Menit';
  }

  static String _firstLabelText(dynamic raw) {
    if (raw == null) return '-';
    if (raw is List) {
      for (final e in raw) {
        final s = (e ?? '').toString().trim();
        if (s.isNotEmpty) return s;
      }
      return '-';
    }

    final s = raw.toString().trim();
    if (s.isEmpty) return '-';
    final cleaned = s
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '');
    final parts = cleaned.split(RegExp(r'[|,]'));
    for (final p in parts) {
      final v = p.trim();
      if (v.isNotEmpty) return v;
    }
    return '-';
  }

  void _toast(BuildContext context, String msg) {
    AppNotify.show(context, msg, type: AppNotifyType.info);
  }

  void _showPanduanSingkat() {
    PanduanSingkatDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: AuthStorage().getDisplayName(),
                builder: (context, snapshot) {
                  final name = snapshot.data ?? 'Pengguna';
                  return TumbuhHeader(
                    title: 'Halo, $name',
                    subtitle: 'Semoga harimu indah...',
                    onProfileTap: () => showLogoutDialog(context),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _showPanduanSingkat,
                          tooltip: 'Panduan',
                          icon: const Icon(
                            Icons.help_outline_rounded,
                            color: AppTheme.brandGreen,
                            size: 26,
                          ),
                        ),
                        const Icon(
                          Icons.wb_sunny_outlined,
                          color: Colors.amber,
                          size: 28,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Banner katalog produk scrollable
              Column(
                children: [
                  SizedBox(
                    height: 145,
                    child: _loadingTopKatalog
                        ? const Center(child: CircularProgressIndicator())
                        : _topKatalogProducts.isEmpty
                        ? Center(
                            child: Text(
                              _topKatalogError ?? 'Belum ada produk katalog.',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.axis != Axis.horizontal) {
                                return false;
                              }
                              const double itemExtent = 300 + 12;
                              final int nextIndex =
                                  (n.metrics.pixels / itemExtent).round().clamp(
                                    0,
                                    _topKatalogProducts.length - 1,
                                  );
                              if (nextIndex != _topKatalogActiveIndex) {
                                setState(
                                  () => _topKatalogActiveIndex = nextIndex,
                                );
                              }
                              return false;
                            },
                            child: ListView.separated(
                              controller: _topKatalogScroll,
                              scrollDirection: Axis.horizontal,
                              itemCount: _topKatalogProducts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final p = _topKatalogProducts[i];
                                final String imageUrl =
                                    (p['imageUrl'] ?? p['image'] ?? '')
                                        .toString();
                                final String title =
                                    (p['title'] ?? p['name'] ?? '').toString();
                                final String subtitle =
                                    '${(p['price'] ?? '').toString()} • ${_labelText(p)} • ${(p['location'] ?? '-').toString()}';

                                return SizedBox(
                                  width: 300,
                                  child: _HighlightBanner(
                                    recipe: _Recipe(
                                      title: title,
                                      subtitle: subtitle,
                                      imageUrl: imageUrl,
                                    ),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetailKatalogPage(product: p),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  _dots(
                    count: _topKatalogProducts.length,
                    activeIndex: _topKatalogActiveIndex,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _MenuGrid(
                onTapResep: widget.onNavigateToIndex != null
                    ? () => widget.onNavigateToIndex!(1)
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ResepPage()),
                      ),
                onTapKatalog: widget.onNavigateToIndex != null
                    ? () => widget.onNavigateToIndex!(4)
                    : () => _toast(context, 'Ke halaman Katalog'),
                onTapScan: widget.onNavigateToIndex != null
                    ? () => widget.onNavigateToIndex!(2)
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ScanPage()),
                      ),
                onTapVideo: widget.onNavigateToIndex != null
                    ? () => widget.onNavigateToIndex!(3)
                    : () => _toast(context, 'Ke halaman Video Edukasi'),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resep Disukai',
                    style: t.titleMedium?.copyWith(
                      color: AppTheme.brandGreenDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ResepDisukaiPage(),
                        ),
                      );
                    },
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: _loadingLikedRecipes
                        ? const Center(child: CircularProgressIndicator())
                        : _likedRecipesPreview.isEmpty
                        ? Center(
                            child: Text(
                              _likedRecipesError ??
                                  'Belum ada resep yang disukai.',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.axis != Axis.horizontal) {
                                return false;
                              }
                              const double itemExtent = 175 + 10;
                              final int nextIndex =
                                  (n.metrics.pixels / itemExtent).round().clamp(
                                    0,
                                    _likedRecipesPreview.length - 1,
                                  );
                              if (nextIndex != _likedRecipesActiveIndex) {
                                setState(
                                  () => _likedRecipesActiveIndex = nextIndex,
                                );
                              }
                              return false;
                            },
                            child: ListView.separated(
                              controller: _likedRecipesScroll,
                              scrollDirection: Axis.horizontal,
                              itemCount: _likedRecipesPreview.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final r = _likedRecipesPreview[i];
                                final String title =
                                    (r['name'] ?? r['title'] ?? '').toString();
                                final String duration = _durationText(
                                  r['cookingTime'],
                                );
                                final String firstLabel = _firstLabelText(
                                  r['label'],
                                );
                                final String subtitle =
                                    '$duration • ${firstLabel.trim().isEmpty ? '-' : firstLabel}';

                                return _RecipeCardSmall(
                                  recipe: _Recipe(
                                    title: title,
                                    subtitle: subtitle,
                                    imageUrl: (r['imageUrl'] ?? '').toString(),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DetailResepPage(recipe: r),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  final _Recipe recipe;
  final VoidCallback onTap;

  const _HighlightBanner({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Gambar utama, full cover
            Positioned.fill(
              child: Image.network(recipe.imageUrl, fit: BoxFit.cover),
            ),
            // Overlay gradient gelap hanya di bawah
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
            // Judul, subjudul, dan tombol panah
            Positioned(
              left: 14,
              right: 14,
              bottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recipe.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium?.copyWith(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final VoidCallback onTapResep;
  final VoidCallback onTapKatalog;
  final VoidCallback onTapScan;
  final VoidCallback onTapVideo;

  const _MenuGrid({
    required this.onTapResep,
    required this.onTapKatalog,
    required this.onTapScan,
    required this.onTapVideo,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandGreen.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandGreen.withOpacity(0.1),
                  AppTheme.brandGreen.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Fitur Utama',
                  style: t.titleMedium?.copyWith(
                    color: AppTheme.brandGreenDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, color: AppTheme.brandGreen, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '4 Fitur',
                        style: TextStyle(
                          color: AppTheme.brandGreenDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.08,
              children: [
                _MenuTile(
                  title: 'Resep',
                  icon: Image.asset(
                    'assets/icons/resep.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                  filled: true,
                  onTap: onTapResep,
                ),
                _MenuTile(
                  title: 'Katalog',
                  icon: Image.asset(
                    'assets/icons/katalog.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                  filled: false,
                  onTap: onTapKatalog,
                ),
                _MenuTile(
                  title: 'Scan',
                  icon: Image.asset(
                    'assets/icons/scan.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                  filled: false,
                  onTap: onTapScan,
                ),
                _MenuTile(
                  title: 'Video',
                  icon: Image.asset(
                    'assets/icons/video.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                  filled: true,
                  onTap: onTapVideo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final Widget icon;
  final bool filled;
  final VoidCallback onTap;

  const _MenuTile({
    required this.title,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: filled
              ? LinearGradient(
                  colors: [
                    AppTheme.brandGreen,
                    AppTheme.brandGreen.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: filled ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: filled
              ? null
              : Border.all(
                  color: AppTheme.brandGreen.withOpacity(0.12),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: filled
                  ? AppTheme.brandGreen.withOpacity(0.25)
                  : Colors.black.withOpacity(0.04),
              blurRadius: filled ? 12 : 8,
              offset: Offset(0, filled ? 4 : 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: filled
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.brandGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: SizedBox(width: 42, height: 42, child: icon),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: t.titleMedium?.copyWith(
                color: filled ? Colors.white : AppTheme.brandGreenDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCardSmall extends StatelessWidget {
  final _Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCardSmall({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 112,
              width: double.infinity,
              child: Image.network(recipe.imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    recipe.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Recipe {
  final String title;
  final String subtitle;
  final String imageUrl;

  const _Recipe({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}
