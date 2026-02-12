import 'package:flutter/material.dart';
// Import theme tetap dipertahankan karena kemungkinan besar dibutuhkan untuk AppTheme di widget lain
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreateKatalogPage extends StatefulWidget {
  const CreateKatalogPage({super.key});

  @override
  State<CreateKatalogPage> createState() => _CreateKatalogPageState();
}

class _CreateKatalogPageState extends State<CreateKatalogPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _waController = TextEditingController();

  String selectedCategory = 'Masakan';

  @override
  void dispose() {
    // Praktik terbaik: hapus controller saat widget dihancurkan
    _namaController.dispose();
    _hargaController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _waController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Jual Hasil Panenmu!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D)),
            ),
            const SizedBox(height: 25),

            // TOMBOL AMBIL FOTO
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF9B800),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: InkWell(
                onTap: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.black54, size: 30),
                    SizedBox(width: 15),
                    Text(
                      'Ambil Foto Produk',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            _buildInputField(
              controller: _namaController,
              hint: 'Masukan Nama Produk (contoh: Salad Ibu Ayu)',
              icon: Icons.shopping_basket_outlined,
            ),
            const SizedBox(height: 15),

            _buildInputField(
              controller: _hargaController,
              hint: 'Masukan Harga Produk (contoh: 15000)',
              icon: Icons.attach_money, // Mengganti Icons.money yang tidak standar
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryItem('Sayur', const Color(0xFF67B9A4)),
                  _buildCategoryItem('Buah', const Color(0xFFFF9F43)),
                  _buildCategoryItem('Masakan', const Color(0xFF6B9245), isSelected: true),
                  _buildCategoryItem('Cemilan', const Color(0xFFEB5757)),
                  _buildCategoryItem('Minuman', Colors.white, textColor: Colors.black),
                  _buildCategoryItem('Lainnya', const Color(0xFF4A90E2)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Lokasi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            _buildInputField(
              controller: _lokasiController,
              hint: 'Masukan Lokasi Produk (contoh: Cipageran)',
              icon: Icons.location_on,
            ),
            const SizedBox(height: 15),
            _buildInputField(
              controller: _deskripsiController,
              hint: 'Masukan Deksripsi (contoh : hasil panen kebun sendiri, bebas pestisida)',
              icon: Icons.edit_note,
            ),
            const SizedBox(height: 15),
            
            // PERBAIKAN: Menggunakan FontAwesome untuk ikon WhatsApp
            _buildInputField(
              controller: _waController,
              hint: 'Masukan Link Wa (contoh: https://wa.me/62812345678)',
              icon: FontAwesomeIcons.whatsapp, 
              isFontAwesome: true,
              iconColor: Colors.green,
            ),
            const SizedBox(height: 35),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B9245),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_box_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Simpan Produk',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B9245), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isFontAwesome = false,
    TextInputType keyboardType = TextInputType.text,
    Color iconColor = Colors.black45,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          // Mengatur prefixIcon berdasarkan jenis library ikon yang digunakan
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: FaIcon(icon, color: iconColor, size: 20),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, Color color, {bool isSelected = false, Color textColor = Colors.white}) {
    bool isSelected = selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title; // Ubah kategori yang dipilih
        });
      },
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: color == Colors.white ? Border.all(color: Colors.grey.shade300) : null,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Center(
                  child: Text(
                    title.substring(0, 1),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, color: Color.fromARGB(255, 11, 94, 0), size: 16),
                  ),
                )
            ],
          ),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    )
    );
  }
}