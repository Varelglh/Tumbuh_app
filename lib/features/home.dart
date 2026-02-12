import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'resep/resep.dart';
import 'scan/scan.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int>? onNavigateToIndex;
  const HomePage({super.key, this.onNavigateToIndex});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final highlight = _Recipe(
      title: 'Salad sayur segar bu Ayu',
      subtitle: 'Rp.15.000 • Ibu Ayu • Desa Cipageran',
      imageUrl:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
    );

    final favorites = <_Recipe>[
      _Recipe(
        title: 'Tumis Kangkung',
        subtitle: '15 menit • Mudah',
        imageUrl:
            'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
      ),
      _Recipe(
        title: 'Sup Sayur',
        subtitle: '25 menit • Mudah',
        imageUrl:
            'https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=1200&q=80',
      ),
      _Recipe(
        title: 'Tempe Orek',
        subtitle: '20 menit • Mudah',
        imageUrl:
            'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=80',
      ),
      _Recipe(
        title: 'Pepes Ikan',
        subtitle: '30 menit • Sedang',
        imageUrl:
            'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=1200&q=80',
      ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              name: 'Halo, Sari',
              subtitle: 'Semoga harimu indah...',
              onProfileTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buka Profil (placeholder)')),
                );
              },
            ),
            const SizedBox(height: 14),

            _HighlightBanner(
              recipe: highlight,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Buka detail: ${highlight.title}')),
                );
              },
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 10),

            _MenuGrid(
              onTapResep: onNavigateToIndex != null
                  ? () => onNavigateToIndex!(1)
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ResepPage()),
                    ),
              onTapKatalog: onNavigateToIndex != null
                  ? () => onNavigateToIndex!(4)
                  : () => _toast(context, 'Ke halaman Katalog'),
              onTapScan: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScanPage()),
                  );
                },
              onTapVideo: onNavigateToIndex != null
                  ? () => onNavigateToIndex!(3)
                  : () => _toast(context, 'Ke halaman Video Edukasi'),
            ),

            const SizedBox(height: 18),

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
                  onPressed: () => _toast(context, 'Lihat semua resep disukai'),
                  child: const Text('Lihat semua'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final r = favorites[i];
                  return _RecipeCardSmall(
                    recipe: r,
                    onTap: () => _toast(context, 'Buka detail: ${r.title}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onProfileTap;

  const _Header({
    required this.name,
    required this.subtitle,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(999),
          child: const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFFE8E3D9),
            child: Icon(Icons.person, color: AppTheme.brandGreenDark, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppTheme.brandGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        const Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 30),
      ],
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
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(recipe.imageUrl, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandGreen.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Fitur Utama',
                  style: t.titleMedium?.copyWith(
                    color: AppTheme.brandGreenDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, color: AppTheme.brandGreen, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '4 Fitur',
                        style: TextStyle(
                          color: AppTheme.brandGreenDark,
                          fontSize: 11,
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.0,
              children: [
                _MenuTile(
                  title: 'Resep',
                  icon: Image.asset(
                    'assets/icons/resep.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  filled: true,
                  onTap: onTapResep,
                ),
                _MenuTile(
                  title: 'Katalog',
                  icon: Image.asset(
                    'assets/icons/katalog.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  filled: false,
                  onTap: onTapKatalog,
                ),
                _MenuTile(
                  title: 'Scan',
                  icon: Image.asset(
                    'assets/icons/scan.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                  filled: false,
                  onTap: onTapScan,
                ),
                _MenuTile(
                  title: 'Video',
                  icon: Image.asset(
                    'assets/icons/video.png',
                    width: 50,
                    height: 50,
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
      borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(18),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: filled
                    ? Colors.white.withOpacity(0.2)
                    : AppTheme.brandGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SizedBox(width: 48, height: 48, child: icon),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: t.titleMedium?.copyWith(
                color: filled ? Colors.white : AppTheme.brandGreenDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 100,
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
                  const SizedBox(height: 3),
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
