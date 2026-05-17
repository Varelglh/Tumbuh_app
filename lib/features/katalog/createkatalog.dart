import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/services/products_api.dart';
import 'package:tumbuh_app/core/utils/app_notify.dart';
import 'package:tumbuh_app/core/utils/products_refresh.dart';

class CreateKatalogPage extends StatefulWidget {
  const CreateKatalogPage({super.key, this.product});

  final Map<String, dynamic>? product;

  @override
  State<CreateKatalogPage> createState() => _CreateKatalogPageState();
}

class _CreateKatalogPageState extends State<CreateKatalogPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _waController = TextEditingController();

  String selectedCategory = 'Masakan';

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _image;
  bool _isSubmitting = false;

  bool get _isEdit => widget.product != null;

  static String _safeString(dynamic v) => (v ?? '').toString();

  static String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  @override
  void initState() {
    super.initState();

    final p = widget.product;
    if (p == null) return;

    _namaController.text = _safeString(p['name'] ?? p['title']);
    final dynamic priceRaw = p['priceRaw'] ?? p['price'];
    final int? parsedPrice = _parsePrice(priceRaw);
    if (parsedPrice != null) _hargaController.text = parsedPrice.toString();

    final int? stock = _parseIntDigitsOnly(_safeString(p['stock']));
    if (stock != null) _stockController.text = stock.toString();

    _labelController.text = _safeString(p['label'] ?? p['author']);
    _lokasiController.text = _safeString(p['location']);
    _deskripsiController.text = _safeString(p['description']);
    _waController.text = _digitsOnly(_safeString(p['whatsappLink']));

    final String cat = _safeString(p['category']).trim();
    if (cat.isNotEmpty) selectedCategory = cat;
  }

  void _snack(String message, {AppNotifyType type = AppNotifyType.error}) {
    if (!mounted) return;
    AppNotify.show(context, message, type: type);
  }

  static int? _parseIntDigitsOnly(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  static int? _parsePrice(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();

    final String s = raw.toString().trim();
    if (s.isEmpty) return null;

    final String compact = s.replaceAll(RegExp(r'\s+'), '');

    // If backend sends something like "1500000.0", parse as double and round
    // so we don't accidentally append decimal digits when stripping non-digits.
    if (RegExp(r'^\d+(?:[\.,]\d+)?$').hasMatch(compact)) {
      final double? d = double.tryParse(compact.replaceAll(',', '.'));
      if (d != null) return d.round();
    }

    // Fallback for formatted currency like "Rp.1.500.000".
    return _parseIntDigitsOnly(compact);
  }

  static String? _normalizeWhatsappNumber(String raw) {
    final String digits0 = _digitsOnly(raw);
    if (digits0.isEmpty) return null;

    // Normalisasi sederhana untuk nomor Indonesia:
    // - 08xxxx -> 62xxxx
    // - 8xxxx  -> 62xxxx
    // - 62xxxx -> tetap
    String digits = digits0;
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    } else if (digits.startsWith('8')) {
      digits = '62$digits';
    }
    if (digits.isEmpty) return null;

    // Validasi ringan: E.164 biasanya 9-15 digit (tanpa +).
    if (digits.length < 9 || digits.length > 15) return null;
    return digits;
  }

  String _dioErrorToMessage(DioException e) {
    final int? status = e.response?.statusCode;
    final dynamic data = e.response?.data;

    String? serverMessage;
    if (data is Map) {
      final dynamic m = data['message'] ?? data['error'];
      if (m != null) serverMessage = m.toString();

      // Common validation shape: { errors: { field: [msg] } }
      if ((serverMessage == null || serverMessage.trim().isEmpty) &&
          data['errors'] is Map) {
        final Map<dynamic, dynamic> errors = data['errors'] as Map;
        final List<String> parts = <String>[];
        for (final entry in errors.entries) {
          final String field = entry.key.toString();
          final dynamic v = entry.value;
          if (v is List && v.isNotEmpty) {
            parts.add('$field: ${v.first}');
          } else if (v != null && v.toString().trim().isNotEmpty) {
            parts.add('$field: $v');
          }
        }
        if (parts.isNotEmpty) {
          serverMessage = parts.join('\n');
        }
      }
    } else if (data is String && data.trim().isNotEmpty) {
      serverMessage = data.trim();
    }

    String? normalizeValidationMessage(String? raw) {
      final String s = (raw ?? '').trim();
      if (s.isEmpty) return null;
      final lower = s.toLowerCase();

      // Common numeric validation from backend (e.g. class-validator):
      // "price must not be less than 500"
      if (lower.contains('price') &&
          (lower.contains('must not be less than') ||
              lower.contains('should not be less than') ||
              (lower.contains('min') && lower.contains('price')))) {
        final m = RegExp(r'less than\s+(\d+)').firstMatch(lower);
        final minStr = m?.group(1);
        if (minStr != null && minStr.trim().isNotEmpty) {
          return 'Harga minimal $minStr.';
        }
        return 'Harga terlalu kecil.';
      }

      if (lower.contains('description') &&
          (lower.contains('longer than or equal to 10') ||
              lower.contains('at least 10') ||
              lower.contains('min') && lower.contains('10'))) {
        return 'Deskripsi minimal 10 karakter.';
      }

      if (lower.contains('name') && lower.contains('must')) {
        return 'Nama produk tidak valid.';
      }

      return s;
    }

    // Handle common backend shape: { statusCode, message: [..], timestamp }
    if (data is Map && data['message'] is List) {
      final List<dynamic> msgs = data['message'] as List<dynamic>;
      final String combined = msgs.map((e) => e.toString()).join('\n');
      serverMessage = combined;
    }

    serverMessage = normalizeValidationMessage(serverMessage) ?? serverMessage;

    // Prefer user-friendly messages for common cases.
    if (status == 401 || status == 403) {
      return 'Sesi login habis / tidak berizin. Silakan login ulang.';
    }

    if (status == 413) {
      return 'Ukuran foto terlalu besar. Coba ambil ulang fotonya.';
    }

    if (status == 400 || status == 422) {
      return serverMessage?.trim().isNotEmpty == true
          ? serverMessage!.trim()
          : 'Data produk tidak valid. Periksa inputmu.';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak ada koneksi internet / server tidak bisa diakses.';
      default:
        break;
    }

    return serverMessage?.trim().isNotEmpty == true
        ? serverMessage!.trim()
        : 'Gagal menyimpan produk. Coba lagi.';
  }

  Future<void> _pickImageFrom(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (!mounted) return;
      setState(() {
        _image = picked;
      });
    } catch (_) {
      _snack(
        source == ImageSource.camera
            ? 'Gagal membuka kamera.'
            : 'Gagal membuka galeri.',
        type: AppNotifyType.error,
      );
    }
  }

  Future<void> _showPickImageSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFrom(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFrom(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final Map<String, dynamic>? editing = widget.product;
    final String editingId = _safeString(editing?['id']).trim();

    final String name = _namaController.text.trim();
    final String labelInput = _labelController.text.trim();
    final String description = _deskripsiController.text.trim();
    final String location = _lokasiController.text.trim();
    final String waRaw = _waController.text.trim();
    final String? whatsappNumber = _normalizeWhatsappNumber(waRaw);
    final int? price = _parseIntDigitsOnly(_hargaController.text);
    final int? stock = _parseIntDigitsOnly(_stockController.text);

    if (name.isEmpty) return _snack('Nama produk wajib diisi.');
    if (price == null || price <= 0) return _snack('Harga produk tidak valid.');
    if (stock == null || stock <= 0) return _snack('Stock produk tidak valid.');
    if (location.isEmpty) return _snack('Lokasi wajib diisi.');
    if (description.isEmpty) return _snack('Deskripsi wajib diisi.');
    if (description.length < 10) {
      return _snack('Deskripsi minimal 10 karakter.');
    }
    if (whatsappNumber == null) {
      return _snack('Nomor WhatsApp tidak valid. Contoh: 62812345678');
    }
    final bool hasExistingImage = _safeString(
      editing?['imageUrl'] ?? editing?['image'],
    ).trim().isNotEmpty;
    if (!_isEdit && _image == null) {
      return _snack('Foto produk wajib dipilih.');
    }
    if (_isEdit && _image == null && !hasExistingImage) {
      return _snack('Foto produk wajib dipilih.');
    }

    final String? token = await AuthStorage().getToken();
    if (token == null || token.isEmpty) {
      return _snack('Sesi login habis. Silakan login ulang.');
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final String labelToSend = labelInput.isNotEmpty
          ? labelInput
          : selectedCategory;

      if (_isEdit) {
        if (editingId.isEmpty) {
          throw const FormatException('Missing product id for edit');
        }

        await ProductsApi().updateProduct(
          id: editingId,
          token: token,
          name: name,
          description: description,
          label: labelToSend,
          category: selectedCategory,
          price: price,
          location: location,
          whatsappLink: whatsappNumber,
          stock: stock,
          imagePath: _image?.path,
          imageFileName: _image?.name,
        );
      } else {
        await ProductsApi().createProduct(
          token: token,
          name: name,
          description: description,
          label: labelToSend,
          category: selectedCategory,
          price: price,
          location: location,
          whatsappLink: whatsappNumber,
          stock: stock,
          imagePath: _image!.path,
          imageFileName: _image!.name,
        );
      }

      if (!mounted) return;
      _snack(
        _isEdit ? 'Produk berhasil diperbarui.' : 'Produk berhasil disimpan.',
        type: AppNotifyType.success,
      );
      ProductsRefresh.bump();
      Navigator.pop(context, true);
    } on DioException catch (e) {
      _snack(_dioErrorToMessage(e));
    } catch (_) {
      _snack('Gagal menyimpan produk. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Praktik terbaik: hapus controller saat widget dihancurkan
    _namaController.dispose();
    _hargaController.dispose();
    _stockController.dispose();
    _labelController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    _waController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D2D2D),
              ),
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _showPickImageSheet,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      color: Colors.black54,
                      size: 30,
                    ),
                    const SizedBox(width: 15),
                    Text(
                      _image == null
                          ? 'Pilih Foto Produk'
                          : 'Foto Produk Dipilih',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_image != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_image!.path),
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
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
              icon: Icons
                  .attach_money, // Mengganti Icons.money yang tidak standar
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 15),

            _buildInputField(
              controller: _stockController,
              hint: 'Masukan Stock Produk (contoh: 10)',
              icon: Icons.inventory_2_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              height: 82,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                children: [
                  _buildCategoryItem(
                    'Camilan',
                    const Color(0xFFEB5757),
                    circleSize: 60,
                    letterFontSize: 12,
                    labelFontSize: 11,
                  ),
                  _buildCategoryItem(
                    'Masakan',
                    const Color(0xFF6B9245),
                    circleSize: 60,
                    letterFontSize: 12,
                    labelFontSize: 11,
                  ),
                  _buildCategoryItem(
                    'Minuman',
                    Colors.white,
                    textColor: Colors.black,
                    circleSize: 60,
                    letterFontSize: 12,
                    labelFontSize: 11,
                  ),
                  _buildCategoryItem(
                    'Bahan Mentah',
                    const Color(0xFF4A90E2),
                    outerPadding: EdgeInsets.zero,
                    circleSize: 60,
                    letterFontSize: 12,
                    labelFontSize: 11,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Label',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            _buildInputField(
              controller: _labelController,
              hint: 'Masukan Label (contoh: sayuran, organik, dll)',
              icon: Icons.label_outline,
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
              hint:
                  'Masukan Deksripsi (contoh : hasil panen kebun sendiri, bebas pestisida)',
              icon: Icons.edit_note,
            ),
            const SizedBox(height: 15),

            _buildInputField(
              controller: _waController,
              hint: 'Masukan Nomor WA (contoh: 62812345678)',
              icon: FontAwesomeIcons.whatsapp,
              iconColor: Colors.green,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 15),
            const SizedBox(height: 35),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B9245),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_box_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Simpan Produk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF6B9245),
                  fontWeight: FontWeight.bold,
                ),
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
    TextInputType keyboardType = TextInputType.text,
    Color iconColor = Colors.black45,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
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

  Widget _buildCategoryItem(
    String title,
    Color color, {
    Color textColor = Colors.white,
    EdgeInsets outerPadding = const EdgeInsets.only(right: 12),
    double circleSize = 50,
    double letterFontSize = 10,
    double labelFontSize = 10,
  }) {
    final bool isSelected = selectedCategory == title;
    return Padding(
      padding: outerPadding,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = title; // Ubah kategori yang dipilih
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: color == Colors.white
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      title.substring(0, 1),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: letterFontSize,
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color.fromARGB(255, 11, 94, 0),
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: labelFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
