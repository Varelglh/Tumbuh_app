import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:tumbuh_app/app/theme.dart';

const List<String> supportedScanIngredients = <String>[
  'ayam',
  'telur',
  'kentang',
  'tempe',
  'jagung',
  'terong ungu',
];

const Map<String, List<String>> _scanIngredientAliases = <String, List<String>>{
  'ayam': <String>['ayam', 'chicken'],
  'telur': <String>['telur', 'egg', 'eggs'],
  'kentang': <String>['kentang', 'potato', 'potatoes'],
  'tempe': <String>['tempe', 'tempeh'],
  'jagung': <String>['jagung', 'corn', 'maize'],
  'terong ungu': <String>[
    'terong ungu',
    'terong_ungu',
    'terong-ungu',
    'eggplant',
    'purple eggplant',
    'purple_eggplant',
    'aubergine',
  ],
};

String? matchSupportedScanIngredient(String rawValue) {
  final normalizedValue = rawValue
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (normalizedValue.isEmpty) {
    return null;
  }

  for (final entry in _scanIngredientAliases.entries) {
    for (final alias in entry.value) {
      final normalizedAlias = alias
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (normalizedAlias == normalizedValue) {
        return entry.key;
      }
    }
  }

  return null;
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, this.scanner});

  final Widget? scanner;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // Gunakan variabel ini agar semua elemen merujuk pada ukuran yang sama
  final double scanBoxSize = 280.0;
  final double verticalOffset = -60.0; // Menggeser titik fokus sedikit ke atas tengah
  String? _detectedIngredient;
  String? _lastScanValue;

  bool get _isIngredientRecognized => _detectedIngredient != null;

  String get _scanTooltipText =>
      _isIngredientRecognized ? '${_detectedIngredient!.toUpperCase()} terdeteksi' : 'Bahan belum dikenali';

  String get _scanTitleText =>
      _isIngredientRecognized ? '${_capitalizeIngredient(_detectedIngredient!)} Terdeteksi' : 'Bahan belum dikenali';

  String get _scanSubtitleText =>
      _isIngredientRecognized ? 'Bahan berhasil dikenali' : 'Scan hanya mendukung bahan tertentu';

  String get _scanSummaryText => _isIngredientRecognized
      ? '${_capitalizeIngredient(_detectedIngredient!)} berhasil dikenali. Informasi gizi lengkap untuk bahan ini akan tersedia pada pembaruan berikutnya.'
      : 'Coba arahkan kamera ke ayam, telur, kentang, tempe, jagung, atau terong ungu.';

  void _handleBarcodeCapture(BarcodeCapture capture) {
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere(
          (value) => value.isNotEmpty,
          orElse: () => '',
        );

    if (rawValue.isEmpty || rawValue == _lastScanValue) {
      return;
    }

    _lastScanValue = rawValue;
    final ingredient = matchSupportedScanIngredient(rawValue);

    if (ingredient != null) {
      setState(() {
        _detectedIngredient = ingredient;
      });
      return;
    }

    setState(() {
      _detectedIngredient = null;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Bahan belum bisa terdeteksi'),
        ),
      );
  }

  String _capitalizeIngredient(String value) {
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) => '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. KAMERA DASAR
          widget.scanner ?? MobileScanner(onDetect: _handleBarcodeCapture),

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
                      child: Text(
                        _scanTooltipText,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                    Text(
                      _scanTitleText,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                    ),
                    Text(
                      _scanSubtitleText,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    
                    const SizedBox(height: 25),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bahan yang bisa di-scan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brandGreenDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: supportedScanIngredients
                          .map((ingredient) => _buildModernChip(_capitalizeIngredient(ingredient), AppTheme.brandGreen))
                          .toList(),
                    ),
                    
                    const SizedBox(height: 30),
                    // Button
                    ElevatedButton(
                      onPressed: _isIngredientRecognized ? () {} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandGreen,
                        disabledBackgroundColor: Colors.grey[300],
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Lihat Detail Gizi Lengkap', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    
                    const SizedBox(height: 30),
                    const Text("Ringkasan Scan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      _scanSummaryText,
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
      child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
