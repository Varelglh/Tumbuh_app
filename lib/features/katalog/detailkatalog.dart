import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetailKatalogPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const DetailKatalogPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Menggunakan ExtendBodyBehindAppBar agar gambar terlihat sampai ke atas status bar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.9),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              child: IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),

      // ===== BUTTON HUBUNGI PENJUAL =====
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
          label: const Text(
            'Hubungi Penjual',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== IMAGE SECTION =====
            Stack(
              children: [
                Hero(
                  tag: product['title'],
                  child: Image.network(
                    product['image'],
                    height: 350,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Efek gradient di bagian bawah gambar agar transisi ke konten lebih halus
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),

            // ===== CONTENT SECTION =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Harga dan Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['price'],
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.brandGreen,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Stok Tersedia',
                          style: TextStyle(color: AppTheme.brandGreen, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product['title'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),

                  // Info Penjual (Dibuat lebih menarik dengan Row)
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE8E3D9),
                        child: Icon(Icons.store, color: AppTheme.brandGreen),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['author'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            'KWT Cipageran • ${product['location']}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(height: 1),
                  ),

                  // ===== DESKRIPSI =====
                  const Text(
                    'Tentang Produk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Salad segar dari hasil panen kebun sendiri, bebas pestisida dan dijamin segar setiap hari. Cocok untuk diet sehat dan konsumsi harian keluarga.',
                    style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7), height: 1.5),
                  ),

                  const SizedBox(height: 24),

                  // ===== KOLOM PENILAIAN (RATING) =====
                  const Text(
                    'Penilaian Produk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${product['rating']}',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                                ),
                                const Text('/ 5.0', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildRatingBar(5, 0.9), // Contoh 90% bintang 5
                                  _buildRatingBar(4, 0.1),
                                  _buildRatingBar(3, 0.0),
                                  _buildRatingBar(2, 0.0),
                                  _buildRatingBar(1, 0.0),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Lihat Semua ${product['reviews']} Ulasan',
                            style: const TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Spacer agar tidak tertutup button bawah
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk bar rating
  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.black12,
                color: Colors.amber,
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}