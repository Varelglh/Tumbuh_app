import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/features/scan/scan.dart';
import 'home.dart';
import 'resep/resep.dart';
import 'video/video.dart';
import 'katalog/katalog.dart';
import 'resep/reseppintar_hasil.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      HomePage(onNavigateToIndex: (i) => setState(() => _index = i)),
      const ResepPage(),
      const ScanPage(),
      const VideoPage(),
      const KatalogPage(),
      const HasilResepPage(),
    ];
  }

  Widget _navItem(IconData icon, IconData selectedIcon, String label, int idx) {
    final selected = _index == idx;
    final color = selected ? AppTheme.brandGreen : Colors.black38;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _index = idx),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.brandGreen.withOpacity(0.1) : Colors.transparent,
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
    return Scaffold(
      extendBody: true,
      body: _pages[_index],
      
      // Menggunakan padding pada FAB agar posisinya sedikit lebih turun (masuk ke notch)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 24), // Menurunkan posisi tombol scan
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              width: 56,
              child: FloatingActionButton(
                onPressed: () => setState(() => _index = 2),
                backgroundColor: AppTheme.brandGreen,
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(Icons.qr_code_scanner_rounded, size: 28, color: Colors.white),
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
            _navItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Resep', 1),
            const SizedBox(width: 70), // Spasi tengah disesuaikan
            _navItem(Icons.ondemand_video_outlined, Icons.ondemand_video_rounded, 'Video', 3),
            _navItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Katalog', 4),
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
      body: Center(
        child: Text(title, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}