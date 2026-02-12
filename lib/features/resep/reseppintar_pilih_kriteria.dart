import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'reseppintar_hasil.dart';

class PilihKriteriaPage extends StatefulWidget {
  const PilihKriteriaPage({super.key});

  @override
  State<PilihKriteriaPage> createState() => _PilihKriteriaPageState();
}

class _PilihKriteriaPageState extends State<PilihKriteriaPage> {
  final List<Map<String, dynamic>> _kriteria = [
    {'label': '+ Protein', 'icon': '🍗'},
    {'label': 'Vegetarian', 'icon': '🥗'},
    {'label': 'Vitamin', 'icon': '🍊'},
    {'label': 'Rendah Kalori', 'icon': '📉'},
    {'label': 'Cepat', 'icon': '🍳'},
  ];

  final Set<int> _selectedKriteria = {};

  @override
  Widget build(BuildContext context) {
    // Kalkulasi lebar kartu agar pas 3 kolom dengan spacing
    double cardWidth = (MediaQuery.of(context).size.width - 80) / 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Header Section
            Column(
              children: [
                Image.asset(
                    'assets/icons/app_icon.png', // Pastikan asset ini ada
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.eco, size: 100, color: AppTheme.brandGreen),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Pilih Kriteria Masakan kamu :',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const Text(
                  '(Centang Kriteria Yang Inginkan)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Grid Kriteria yang Lebih Rapi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 16, // Jarak horizontal antar kartu
                runSpacing: 20, // Jarak vertikal antar baris
                alignment: WrapAlignment.center,
                children: List.generate(_kriteria.length, (index) {
                  final isSelected = _selectedKriteria.contains(index);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedKriteria.remove(index);
                        } else {
                          _selectedKriteria.add(index);
                        }
                      });
                    },
                    child: _buildKriteriaCard(
                      _kriteria[index]['label'],
                      _kriteria[index]['icon'],
                      isSelected,
                      cardWidth,
                    ),
                  );
                }),
              ),
            ),

            const Spacer(),

            // Tombol Cari Resep
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HasilResepPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Cari Resep',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

  Widget _buildKriteriaCard(String label, String icon, bool isSelected, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Checkbox Icon di pojok kiri atas
          Positioned(
            top: -8,
            left: 4,
            child: Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: isSelected ? AppTheme.brandGreen : Colors.grey.shade300,
            ),
          ),
          // Isi Konten
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Container bulat untuk Ikon (sesuai gambar)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F4E8),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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