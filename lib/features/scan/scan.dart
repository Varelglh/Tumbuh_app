import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tumbuh_app/app/theme.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // Gunakan variabel ini agar semua elemen merujuk pada ukuran yang sama
  final double scanBoxSize = 280.0;
  final double verticalOffset = -60.0; // Menggeser titik fokus sedikit ke atas tengah

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA DASAR
          const MobileScanner(),

          // 2. LAYER OVERLAY & FRAME (Disatukan agar Presisi)
          Stack(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        backgroundBlendMode: BlendMode.dstOut,
                      ),
                    ),
                    // LUBANG OVERLAY
                    Align(
                      alignment: Alignment(0, (verticalOffset / (MediaQuery.of(context).size.height / 2))),
                      child: Container(
                        height: scanBoxSize,
                        width: scanBoxSize,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // FRAME PUTIH & TOOLTIP (Tepat di atas lubang)
              Align(
                alignment: Alignment(0, (verticalOffset / (MediaQuery.of(context).size.height / 2))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tooltip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)
                        ],
                      ),
                      child: const Text(
                        'IKAN cocok 100%',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Border Putih
                    Container(
                      width: scanBoxSize,
                      height: scanBoxSize,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. HEADER (Safe Area Friendly)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 15),
                const Text(
                  'Pindai Makanan',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 4. DRAGGABLE PANEL
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                ),
                child: ListView( // Gunakan ListView agar controller terikat sempurna
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(25, 12, 25, 30),
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 45,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'IKAN Terdeteksi',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                    ),
                    const Text('Geser ke atas untuk info nutrisi lengkap', 
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    
                    const SizedBox(height: 25),
                    // Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildModernChip('Kalori Rendah', AppTheme.brandGreen),
                        _buildModernChip('Protein Tinggi', Colors.redAccent),
                        _buildModernChip('Vitamin Tinggi', Colors.orange),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    // Progress Bars
                    _buildLabelBar('Kandungan Lemak', 0.4, '10 G', AppTheme.brandGreen),
                    _buildLabelBar('Kandungan Protein', 0.8, '80%', Colors.redAccent),
                    _buildLabelBar('Kalori Total', 0.6, '15 Kal', Colors.orange),
                    
                    const SizedBox(height: 25),
                    // Button
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Lihat Detail Gizi Lengkap', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    
                    const SizedBox(height: 30),
                    const Text("Ringkasan Kesehatan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    const Text(
                      "Ikan mengandung nutrisi penting seperti omega-3, protein, dan vitamin D. Sangat baik untuk mendukung perkembangan kognitif dan menjaga daya tahan tubuh anak.",
                      style: TextStyle(color: Colors.black87, height: 1.5),
                    ),
                    const SizedBox(height: 100), // Spasi extra agar bisa di-scroll mentok
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // UI Helpers (Chip & Bar)
  Widget _buildModernChip(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 95),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label.replaceFirst(' ', '\n'), textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _buildLabelBar(String label, double progress, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}