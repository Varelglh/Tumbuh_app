import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/features/video/detailvideo.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  final List<Map<String, String>> _videos = const [
    {
      'title': 'Mengenal Gizi Seimbang',
      'author': 'oleh Dr. Rizal',
      'thumb':
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Masakan Makananan Yang Berprotein Tinggi',
      'author': 'Ibu Ayu',
      'thumb':
          'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Tips Memmilih Bahan Masakan yang sehat',
      'author': 'Ibu Dewi',
      'thumb':
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=800&q=80',
    },
  ];

  String _query = '';
  int _selectedChip = 0;
  final List<String> _chips = ['Semua', 'Tutorial', 'Edukasi', 'Pemasaran'];

  List<Map<String, String>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _videos.where((m) {
      final matchQuery =
          q.isEmpty ||
          m['title']!.toLowerCase().contains(q) ||
          m['author']!.toLowerCase().contains(q);
      final matchChip =
          _selectedChip == 0 ||
          _chips[_selectedChip].toLowerCase() == 'semua'; // placeholder
      return matchQuery && matchChip;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                        'Mau belajar apa hari ini...',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.amber,
                  size: 30,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari.....',
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

            // Chips
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
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppTheme.brandGreenDark,
                        fontWeight: FontWeight.w700,
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

            // List
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DetailVideoPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.network(
                                item['thumb']!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item['author']!,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
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
