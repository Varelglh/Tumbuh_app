import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';

class PanduanSingkatDialog extends StatelessWidget {
  const PanduanSingkatDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PanduanSingkatDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.82;
    final maxWidth = media.size.width < 480 ? media.size.width : 480.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Container(
                  color: AppTheme.cream,
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panduan Singkat',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.ink,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cara cepat pakai aplikasi Tumbuh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.black54,
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GuideSection(
                          number: 1,
                          title: 'Menu utama bawah',
                          items: [
                            GuideItem(
                              imagePath: 'assets/Panduan/shell/shell.png',
                              description:
                                  'Di bagian bawah ada menu Beranda, Resep, Scan, Video, dan Katalog. Tekan salah satu menu untuk masuk ke halamannya.',
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        GuideSection(
                          number: 2,
                          title: 'Halaman Beranda',
                          items: [
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Beranda/Tampilan Beranda.png',
                              description:
                                  'Ini tampilan halaman Beranda. Dari sini kamu bisa lanjut ke fitur Resep, Scan, Video, atau Katalog.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Beranda/Fitur utama.png',
                              description:
                                  'Di bagian ini ada pilihan fitur utama. Kamu bisa tekan Resep, Scan, Video, atau Katalog untuk mulai pakai fitur yang kamu mau.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Beranda/Katalog Produk.png',
                              description:
                                  'Ini contoh tampilan Katalog Produk di Beranda. Kamu bisa lihat produk yang tersedia dan lanjut ke halaman Katalog.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Beranda/Resep Disukai.png',
                              description:
                                  'Ini daftar resep yang kamu tandai suka. Jadi kamu bisa cepat buka lagi resep favoritmu.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Beranda/Logout logo.png',
                              description:
                                  'Kalau mau keluar dari akun, tekan tombol keluar (logout) di bagian logo tumbuh ini.',
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        GuideSection(
                          number: 3,
                          title: 'Halaman Resep',
                          items: [
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Tampilan Halaman.png',
                              description:
                                  'Ini tampilan awal halaman Resep. Di sini kamu bisa mulai mencari resep untuk dimasak.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Pencarian.png',
                              description:
                                  'Kalau mau cepat ketemu resep, ketik nama makanan atau bahan di kolom pencarian.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Filter Resep.png',
                              description:
                                  'Kamu bisa pilih sesuai kebutuhan, misalnya resep terbaru, populer, atau berdasarkan kategori.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Daftar Resep.png',
                              description:
                                  'Ini contoh daftar resep yang muncul. Tekan salah satu resep untuk lihat detailnya.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Detail Cara Memasak Resep.png',
                              description:
                                  'Di halaman detail resep, kamu bisa lihat bahan-bahan dan langkah memasaknya.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Tombol Resep pintar.png',
                              description:
                                  'Ada juga fitur Resep Pintar. Fitur ini membantu kamu cari resep dari bahan yang kamu punya.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Resep pintar/Screenshot 2026-02-27 005828.png',
                              description:
                                  'Di Resep Pintar, pilih dulu bahan yang kamu punya di rumah.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Resep pintar/Screenshot 2026-02-27 005905.png',
                              description:
                                  'Setelah pilih bahan, kamu bisa pilih kebutuhanmu (misalnya mau yang sehat atau tinggi protein).',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Resep/Resep pintar/Screenshot 2026-02-27 005912.png',
                              description:
                                  'Nanti akan muncul rekomendasi resep yang paling cocok dengan bahan yang kamu pilih.',
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        GuideSection(
                          number: 4,
                          title: 'Halaman Scan',
                          items: [
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Scan/Tampilan scan.png',
                              description:
                                  'Tekan menu Scan untuk mulai memindai. Arahkan kamera ke bahan atau produk yang mau kamu cek. Kamu bisa langsung pindai atau pilih gambar dari galeri kalau sudah ada gambar bahan yang mau dipindai.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Scan/Detail Gizi Hasil scan.png',
                              description:
                                  'Setelah dipindai, kamu bisa lihat informasi gizinya supaya lebih mudah memilih yang sesuai kebutuhan.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Scan/Daftar resep hasil scan.png',
                              description:
                                  'Dari hasil scan, aplikasi juga bisa menampilkan pilihan resep yang berhubungan dengan bahan tersebut.',
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        GuideSection(
                          number: 5,
                          title: 'Halaman Video',
                          items: [
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Video Edukasi/Tampilan Halaman Video.png',
                              description:
                                  'Di menu Video, kamu bisa melihat daftar video edukasi untuk belajar hal baru.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Video Edukasi/Pencarian.png',
                              description:
                                  'Kalau mau cari video tertentu, ketik judulnya di kolom pencarian.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Video Edukasi/Filter.png',
                              description:
                                  'Kamu bisa pilih video sesuai yang kamu butuhkan, misalnya berdasarkan kategori atau urutan.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Video Edukasi/Informasi Video Edukasi.png',
                              description:
                                  'Tekan salah satu video untuk melihat informasinya sebelum diputar.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Video Edukasi/Detail Penjelasan Video Edukasi.png',
                              description:
                                  'Di halaman ini kamu bisa membaca penjelasan video dan menonton sampai selesai.',
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        GuideSection(
                          number: 6,
                          title: 'Halaman Katalog',
                          items: [
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Tampilan Utama Fitur Katalog Produk.png',
                              description:
                                  'Di menu Katalog, kamu bisa melihat kumpulan produk yang tersedia.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Pencarian Produk.png',
                              description:
                                  'Kalau mau cari produk tertentu, ketik nama produk di kolom pencarian.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Filter Produk.png',
                              description:
                                  'Kamu bisa memilih produk sesuai kebutuhan, misalnya berdasarkan kategori.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Produk Utama.png',
                              description:
                                  'Ini contoh tampilan daftar produk di katalog. Tekan produk untuk lihat detailnya.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Produk Milik Pribadi.png',
                              description:
                                  'Kalau kamu punya produk sendiri, kamu bisa melihat produk milikmu di bagian ini.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Produk saya/Tampilan Produk Milik Pribadi.png',
                              description:
                                  'Ini contoh tampilan daftar produk milikmu (Produk Saya). Disini Kamu bisa Mengubah isi Produk yang sudah di upload dengan cara klik (edit). Kamu juga bisa menghapus produk yang sudah tidak ingin ditampilkan dengan cara klik (hapus).',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Tambah Produk.png',
                              description:
                                  'Kalau mau menambahkan produk, tekan tombol Tambah Produk.',
                            ),
                            GuideItem(
                              imagePath:
                                  'assets/Panduan/Halaman Katalog Produk/Masukan Tambah Produk.png',
                              description:
                                  'Isi data produk sesuai yang diminta, lalu simpan agar produkmu masuk ke katalog.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Ayo Mulai Mencoba !!!',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuideSection extends StatelessWidget {
  final int number;
  final String title;
  final List<GuideItem> items;

  const GuideSection({
    super.key,
    required this.number,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(_GuideItemView.new),
          ],
        ),
      ),
    );
  }
}

class GuideItem {
  final String imagePath;
  final String description;

  const GuideItem({required this.imagePath, required this.description});
}

class _GuideItemView extends StatelessWidget {
  final GuideItem item;
  const _GuideItemView(this.item);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _GuideImage(path: item.imagePath),
        ],
      ),
    );
  }
}

class _GuideImage extends StatelessWidget {
  final String path;
  const _GuideImage({required this.path});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            // Supaya screenshot lebih jelas dibaca, tapi tetap tidak “meledak”.
            minHeight: 180,
            maxHeight: 340,
          ),
          color: AppTheme.cream,
          alignment: Alignment.center,
          child: Image.asset(
            path,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Text(
                  'Gambar panduan tidak ditemukan',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
