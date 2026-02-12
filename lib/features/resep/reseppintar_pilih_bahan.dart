import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'reseppintar_pilih_kriteria.dart'; // Import halaman tujuan selanjutnya

class PilihBahanPage extends StatefulWidget {
  const PilihBahanPage({super.key});

  @override
  State<PilihBahanPage> createState() => _PilihBahanPageState();
}

class _PilihBahanPageState extends State<PilihBahanPage> {
  // List bahan makanan sesuai desain gambar
  final List<Map<String, dynamic>> _bahanPangan = [
    {'name': 'Tomat', 'icon': '🍅'},
    {'name': 'Ayam', 'icon': '🍗'},
    {'name': 'Jagung', 'icon': '🌽'},
    {'name': 'Tahu', 'icon': '⬜'},
    {'name': 'Sayur', 'icon': '🥬'},
    {'name': 'Bawang', 'icon': '🧄'},
    {'name': 'Wortel', 'icon': '🥕'},
    {'name': 'Telur', 'icon': '🥚'},
    {'name': 'Cabai', 'icon': '🌶️'},
  ];

  // Set untuk menyimpan indeks bahan yang dipilih (centang)
  final Set<int> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0), // Warna background krem sesuai gambar
      body: SafeArea(
        child: Column(
          children: [
            // Tomat Back Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Logo dan Teks Judul
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/icons/app_icon.png', // Pastikan asset ini ada
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.eco, size: 100, color: AppTheme.brandGreen),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pilih Bahan pangan kamu :',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D5D5D),
                    ),
                  ),
                  const Text(
                    '(Centang Bahan Yang Tersedia)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Grid Bahan Makanan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _bahanPangan.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedItems.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedItems.remove(index);
                          } else {
                            _selectedItems.add(index);
                          }
                        });
                      },
                      child: _buildIngredientCard(
                        _bahanPangan[index]['name'],
                        _bahanPangan[index]['icon'],
                        isSelected,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Tombol Lanjutkan
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton(
                onPressed: () {
                  // Navigasi ke halaman Pilih Kriteria (4-C)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PilihKriteriaPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Lanjutkan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard(String name, String icon, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Icon Centang (Muncul hanya jika dipilih)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(
                Icons.check,
                size: 14,
                color: isSelected ? AppTheme.brandGreen : Colors.transparent,
              ),
            ),
          ),
          // Isi Card
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D5D5D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}