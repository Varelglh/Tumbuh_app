import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'detailkatalog.dart';
import 'createkatalog.dart';

class KatalogPage extends StatefulWidget {
  const KatalogPage({super.key});

  @override
  State<KatalogPage> createState() => _KatalogPageState();
}

class _KatalogPageState extends State<KatalogPage> {
  final List<Map<String, dynamic>> _products = const [
    {
      'title': 'Salad segar bu Ayu',
      'author': 'Ayu',
      'price': 'Rp.10.000',
      'rating': 5.0,
      'reviews': 120,
      'image':
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
      'location': 'Desa Cigaparan',
    },
    {
      'title': 'Ayam Bakar Madu Pak Sheva',
      'author': 'Sheva',
      'price': 'Rp.15.000',
      'rating': 4.5,
      'reviews': 103,
      'image':
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
      'location': 'Desa Cigaparan',
    },
    {
      'title': 'Ayam Bakar Madu Pak Sheva',
      'author': 'Sheva',
      'price': 'Rp.15.000',
      'rating': 4.5,
      'reviews': 103,
      'image':
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
      'location': 'Desa Cigaparan',
    },
    {
      'title': 'Salad segar bu Ayu',
      'author': 'Ayu',
      'price': 'Rp.10.000',
      'rating': 5.0,
      'reviews': 120,
      'image':
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
      'location': 'Desa Cigaparan',
    },
  ];

  String _query = '';
  int _selectedChip = 1;
  final List<String> _chips = ['Terbaru', 'Populer', 'Camilan', 'Masakan'];

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _products.where((m) {
      return q.isEmpty ||
          m['title'].toLowerCase().contains(q) ||
          m['author'].toLowerCase().contains(q);
    }).toList();
  }

  void _goToDetail(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailKatalogPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), // Bottom padding diatur di GridView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER =====
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFFE8E3D9),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.brandGreenDark,
                    size: 26,
                  ),
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
                          fontSize: 18,
                          color: AppTheme.brandGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mau Belanja apa hari ini...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // ... di dalam Row header ...
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateKatalogPage()),
                );
              },
              borderRadius: BorderRadius.circular(24), // Agar splash effect rapi
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.add_circle, color: Colors.white, size: 28),
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
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),           
              ],
            ),
            const SizedBox(height: 14),

            // ===== SEARCH =====
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari Produk....',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ===== CHIPS =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_chips.length, (i) {
                  final selected = i == _selectedChip;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_chips[i]),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedChip = i),
                      selectedColor: AppTheme.brandGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppTheme.brandGreenDark,
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

            // ===== GRID PRODUK =====
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 260, // Mengunci tinggi card agar seragam
                ),
                itemBuilder: (context, i) {
                  final p = _filtered[i];

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
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: Image.network(
                              p['image'],
                              height: 100, // Tinggi gambar diperbesar sedikit
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['title'],
                                    maxLines: 1, // Dibatasi 1 baris agar tidak merusak layout
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'oleh ${p['author']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                  const Spacer(), // Mendorong harga dan rating ke bawah
                                  Text(
                                    p['price'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.brandGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${p['rating']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '(${p['reviews']})',
                                        style: const TextStyle(fontSize: 10, color: Colors.black45),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 12, color: Colors.red),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          p['location'],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 10, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 30, // Tinggi tombol tetap
                                    child: ElevatedButton(
                                      onPressed: () => _goToDetail(p),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'Pesan',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}