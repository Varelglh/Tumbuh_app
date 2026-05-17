import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/features/scan/scan.dart';
import 'home.dart';
import 'resep/resep.dart';
import 'video/video.dart';
import 'katalog/katalog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  PageController? _pageController;
  final PageStorageBucket _bucket = PageStorageBucket();
  final ValueNotifier<int> _activeIndex = ValueNotifier<int>(0);

  int get _mainTabCount => 5;
  int get _firstRealPage => 1;
  int get _lastRealPage => _mainTabCount;
  int get _leadingWrapPage =>
      0; // duplikat Katalog (untuk swipe kanan dari Home)
  int get _trailingWrapPage =>
      _mainTabCount + 1; // duplikat Home (untuk swipe kiri dari Katalog)

  @override
  void initState() {
    super.initState();
    _ensureController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _activeIndex.dispose();
    super.dispose();
  }

  void _ensureController() {
    // +1 karena ada 1 halaman duplikat di depan.
    _pageController ??= PageController(initialPage: _index + _firstRealPage);
  }

  Widget _buildMainPage(int idx) {
    switch (idx) {
      case 0:
        return HomePage(
          key: const PageStorageKey<String>('tab-home'),
          onNavigateToIndex: _goTo,
        );
      case 1:
        return const ResepPage(key: PageStorageKey<String>('tab-resep'));
      case 2:
        return ScanPage(
          key: const PageStorageKey<String>('tab-scan'),
          onBack: () => _goTo(0),
          activeIndexListenable: _activeIndex,
          tabIndex: 2,
        );
      case 3:
        return const VideoPage(key: PageStorageKey<String>('tab-video'));
      case 4:
        return const KatalogPage(key: PageStorageKey<String>('tab-katalog'));
      default:
        return const SizedBox.shrink();
    }
  }

  List<Widget> _buildPagedChildren() {
    // Susunan PageView:
    // 0: Katalog (duplikat)
    // 1: Home
    // 2: Resep
    // 3: Scan
    // 4: Video
    // 5: Katalog
    // 6: Home (duplikat)
    return <Widget>[
      const KatalogPage(key: PageStorageKey<String>('tab-katalog-wrap')),
      _buildMainPage(0),
      _buildMainPage(1),
      _buildMainPage(2),
      _buildMainPage(3),
      _buildMainPage(4),
      HomePage(
        key: const PageStorageKey<String>('tab-home-wrap'),
        onNavigateToIndex: _goTo,
      ),
    ];
  }

  void _goTo(int idx) {
    _ensureController();
    final controller = _pageController;
    if (controller == null) return;
    if (idx < 0 || idx >= _mainTabCount) return;
    if (idx == _index) return;

    setState(() {
      _index = idx;
      _activeIndex.value = _index;
    });
    controller.animateToPage(
      idx + _firstRealPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _navItem(IconData icon, IconData selectedIcon, String label, int idx) {
    final selected = _index == idx;
    final color = selected ? AppTheme.brandGreen : Colors.black38;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _goTo(idx),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.brandGreen.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selected ? selectedIcon : icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureController();
    final controller = _pageController;
    final children = _buildPagedChildren();

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: PageStorage(
        bucket: _bucket,
        child: PageView(
          controller: controller,
          allowImplicitScrolling: true,
          onPageChanged: (pageIndex) {
            if (pageIndex == _leadingWrapPage) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final c = _pageController;
                if (c?.hasClients ?? false) c!.jumpToPage(_lastRealPage);
                setState(() {
                  _index = _mainTabCount - 1;
                  _activeIndex.value = _index;
                });
              });
              return;
            }

            if (pageIndex == _trailingWrapPage) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final c = _pageController;
                if (c?.hasClients ?? false) c!.jumpToPage(_firstRealPage);
                setState(() {
                  _index = 0;
                  _activeIndex.value = _index;
                });
              });
              return;
            }

            setState(() {
              _index = pageIndex - _firstRealPage;
              _activeIndex.value = _index;
            });
          },
          children: children,
        ),
      ),

      // Menggunakan padding pada FAB agar posisinya sedikit lebih turun (masuk ke notch)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          top: 24,
        ), // Menurunkan posisi tombol scan
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              width: 56,
              child: FloatingActionButton(
                onPressed: () => _goTo(2),
                backgroundColor: AppTheme.brandGreen,
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scan',
              style: TextStyle(
                fontSize: 10,
                fontWeight: _index == 2 ? FontWeight.bold : FontWeight.normal,
                color: _index == 2 ? AppTheme.brandGreen : Colors.black54,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6, // Margin notch yang lebih rapat agar terlihat slim
        color: Colors.white,
        elevation: 10,
        // Ketinggian bar dikecilkan agar tidak terlihat "kebesaran"
        height: 65,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _navItem(Icons.home_outlined, Icons.home_rounded, 'Beranda', 0),
            _navItem(
              Icons.menu_book_outlined,
              Icons.menu_book_rounded,
              'Resep',
              1,
            ),
            const SizedBox(width: 70), // Spasi tengah disesuaikan
            _navItem(
              Icons.ondemand_video_outlined,
              Icons.ondemand_video_rounded,
              'Video',
              3,
            ),
            _navItem(
              Icons.storefront_outlined,
              Icons.storefront_rounded,
              'Katalog',
              4,
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(title, style: const TextStyle(fontSize: 18))),
    );
  }
}
