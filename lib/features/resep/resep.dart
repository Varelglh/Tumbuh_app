import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/features/resep/detailresep.dart';
import 'package:tumbuh_app/features/resep/reseppintar_pilih_bahan.dart';

class Recipe {
  final String title;
  final String subtitle;
  final String imageUrl;
  const Recipe({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

class ResepPage extends StatefulWidget {
  const ResepPage({super.key});

  @override
  State<ResepPage> createState() => _ResepPageState();
}

class _ResepPageState extends State<ResepPage> {
  // --- STATE UNTUK FILTER ---
  String _selectedFilter = 'Terbaru';
  final List<String> _categories = ['Terbaru', 'Populer', 'Camilan', 'Masakan'];
  // ---------------------------

  final List<Recipe> _all = const [
    Recipe(
      title: 'Salad',
      subtitle: 'Buah dan sayur',
      imageUrl:
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
    ),
    Recipe(
      title: 'Ayam Bakar Madu',
      subtitle: 'Daging Ayam',
      imageUrl:
          'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  List<Recipe> _filtered = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filtered = _all;
  }

  void _search(String q) {
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? _all
          : _all
              .where(
                (r) =>
                    r.title.toLowerCase().contains(q.toLowerCase()) ||
                    r.subtitle.toLowerCase().contains(q.toLowerCase()),
              )
              .toList();
    });
  }

  // --- WIDGET BARU: FILTER PILL ---
  Widget _buildFilterPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = cat),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.brandGreen : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppTheme.brandGreen : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.brandGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFE8E3D9),
          child: const Icon(Icons.person, color: AppTheme.brandGreenDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Halo, Sari',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppTheme.brandGreen,
                ),
              ),
              SizedBox(height: 2),
              Text('Mau Masak apa hari ini...', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 30),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 92, bottom: 56),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌞', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bingung mau masak apa hari ini?',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sesuaikan Masakan sehat mu dengan bahan dan kebutuhan yang kamu inginkan, dengan cara klik tombol di bawah ini',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: SizedBox(
              width: 110,
              height: 30,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PilihBahanPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.search, size: 14, color: Colors.white),
                label: const Text(
                  'Klik disini',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  minimumSize: const Size(80, 36),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: _search,
      decoration: InputDecoration(
        hintText: 'Cari Resep.... (Ayam, Sayur, Talas)',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe r) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DetailResepPage(),
          ),
        );
      },
      child: Container(
        height: 128,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Image.network(
                    r.imageUrl,
                    width: 120,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 120,
                        height: 128,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return Container(
                        width: 120,
                        height: 128,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(Icons.favorite_border, color: Colors.red),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(r.subtitle, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _badge(Icons.timer, '30 Menit'),
                        const SizedBox(width: 8),
                        _badge(Icons.local_fire_department, '180 kal'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _tag('Praktis'),
                        const SizedBox(width: 8),
                        _tag('Protein Tinggi'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.brandGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726), // orange
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildBanner(),
              const SizedBox(height: 12),
              _buildSearch(),
              const SizedBox(height: 16), // Memberi sedikit jarak
              _buildFilterPills(), // Menambahkan Filter Pill di sini
              const SizedBox(height: 13),
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
    );
  }
}