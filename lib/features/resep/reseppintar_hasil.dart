import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'detailresep.dart';

class HasilResepPage extends StatefulWidget {
  const HasilResepPage({super.key});

  @override
  State<HasilResepPage> createState() => _HasilResepPageState();
}

class _HasilResepPageState extends State<HasilResepPage> {
  final List<Map<String, dynamic>> _hasilResep = const [
    {
      'title': 'Ayam Bakar Pedas Manis',
      'subtitle': 'Daging Ayam',
      'duration': '30 Menit',
      'calories': '180 kal',
      'tags': ['Vitamin', 'Protein Tinggi'],
      'imageUrl': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?auto=format&fit=crop&w=1200&q=80',
    },
    {
      'title': 'Ayam Bakar Madu',
      'subtitle': 'Daging Ayam',
      'duration': '30 Menit',
      'calories': '180 kal',
      'tags': ['Vitamin', 'Protein Tinggi'],
      'imageUrl': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1200&q=80',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Material widget wajib ada agar InkWell/GestureDetector tidak error
    return Material(
      color: const Color(0xFFF6F6F1), 
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterSection(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _hasilResep.length,
                itemBuilder: (context, index) => _buildRecipeCard(_hasilResep[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Hasil Resep Pintar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _selectedCategory = 'Cepat'; 

  Widget _buildFilterSection() {
    // List kategori sesuai kebutuhan aplikasi
    final List<String> categories = [
      'Cepat',
      'Rendah Kalori',
      'Protein Tinggi',
      'Vegetarian',
    ];

    return Container(
      color: const Color(0xFFF6F6F1), // Warna background header
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((cat) => _filterChip(cat)).toList(),
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final bool isSelected = _selectedCategory == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
        // Di sini kamu bisa menambahkan fungsi untuk memfilter list resep
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandGreen : Colors.white,
          borderRadius: BorderRadius.circular(25), // Pill shape
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.brandGreen, // Teks hijau jika tidak dipilih sesuai gambar
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DetailResepPage())),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 128,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                child: Image.network(
                  r['imageUrl'],
                  width: 120,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  // Mengatasi error 404 agar tidak muncul teks merah/garis kuning
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(r['subtitle'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badge(Icons.timer_outlined, r['duration'], Colors.orange),
                          const SizedBox(width: 6),
                          _badge(Icons.bolt, r['calories'], AppTheme.brandGreen),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: (r['tags'] as List).map((t) => _miniTag(t)).toList()),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _miniTag(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
    );
  }
}