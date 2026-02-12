import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';

class DetailVideoPage extends StatelessWidget {
  const DetailVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F1), // Background krem lembut sesuai desain
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edukasi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPlayerSection(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mengenal Gizi Seimbang',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1D1D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Oleh Dr. Rizal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMainContentCard(),
                  const SizedBox(height: 20),
                  _buildVideoLinksSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
          ),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Mengenal Gizi Seimbang untuk Keluarga Sehat 🌱',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.brandGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Gizi seimbang adalah kunci utama untuk menjaga kesehatan tubuh, baik untuk anak-anak, ibu, maupun seluruh anggota keluarga. Dengan pola makan yang tepat dan seimbang, tubuh akan mendapatkan energi yang cukup.',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Apa Itu Gizi Seimbang?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Susunan makanan sehari-hari yang mengandung zat gizi dalam jenis dan jumlah yang sesuai dengan kebutuhan tubuh. Tidak harus mahal, tetapi cukup dan bervariasi.',
            style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLinksSection() {
    return Column(
      children: [
        _buildLinkItem(
          'Ayo Terapkan Gizi Seimbang melalui Prinsip Isi Piringku',
          'https://www.youtube.com/watch?v=3e2SZB6zzaA',
        ),
        const SizedBox(height: 10),
        _buildLinkItem(
          'Video Edukasi "Gizi Seimbang" (Universitas Brawijaya)',
          'https://www.youtube.com/watch?v=z88lqOdF0-M',
        ),
      ],
    );
  }

  Widget _buildLinkItem(String title, String url) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.brandGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill, color: AppTheme.brandGreen, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}