import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/services/products_api.dart';
import 'package:tumbuh_app/core/services/users_api.dart';
import 'package:tumbuh_app/core/utils/app_notify.dart';
import 'package:tumbuh_app/core/utils/products_refresh.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class DetailKatalogPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const DetailKatalogPage({super.key, required this.product});

  @override
  State<DetailKatalogPage> createState() => _DetailKatalogPageState();

  static String? _extractUserId(Map<String, dynamic> p) {
    final dynamic direct =
        p['userId'] ?? p['user_id'] ?? p['sellerId'] ?? p['ownerId'];
    final String directStr = (direct ?? '').toString().trim();
    if (directStr.isNotEmpty) return directStr;

    final dynamic user = p['user'] ?? p['seller'] ?? p['owner'];
    if (user is Map) {
      final dynamic id = user['id'] ?? user['_id'] ?? user['userId'];
      final String idStr = (id ?? '').toString().trim();
      if (idStr.isNotEmpty) return idStr;
    }

    return null;
  }

  static String _extractSellerFallback(Map<String, dynamic> p) {
    final dynamic user = p['user'] ?? p['seller'] ?? p['owner'];
    if (user is Map) {
      final dynamic name =
          user['name'] ??
          user['fullName'] ??
          user['username'] ??
          user['userName'];
      final String nameStr = (name ?? '').toString().trim();
      if (nameStr.isNotEmpty) return nameStr;
    }

    final String sellerName =
        (p['sellerName'] ?? p['userName'] ?? p['username'] ?? '')
            .toString()
            .trim();
    return sellerName;
  }

  static String _cleanTag(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';

    final lower = s.toLowerCase();
    if (lower == '[]' || lower == 'null' || lower == '-' || lower == 'nan') {
      return '';
    }

    s = s.replaceAll(RegExp("^[\\[\\(\\{\\s\"']+"), '');
    s = s.replaceAll(RegExp("[\\]\\)\\}\\s\"']+\$"), '');
    return s.trim();
  }

  static List<String> _firstTwoLabels(dynamic raw) {
    if (raw == null) return const <String>[];
    final List<String> parts = <String>[];

    if (raw is List) {
      for (final e in raw) {
        final s = _cleanTag((e ?? '').toString());
        if (s.isEmpty) continue;
        if (parts.contains(s)) continue;
        parts.add(s);
        if (parts.length >= 2) break;
      }
      return parts;
    }

    final cleaned = _cleanTag(raw.toString());
    if (cleaned.isEmpty) return const <String>[];

    final split = cleaned.split(RegExp(r'[|,]'));
    for (final p in split) {
      final s = _cleanTag(p);
      if (s.isEmpty) continue;
      if (parts.contains(s)) continue;
      parts.add(s);
      if (parts.length >= 2) break;
    }

    return parts;
  }

  static String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  /// Backend bisa mengirim `whatsappLink` sebagai URL atau hanya nomor.
  /// Untuk UI/aksi, normalisasi ke URL `https://wa.me/<nomor>`.
  static String normalizeWhatsappToUrl(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
      return trimmed;
    }

    final String digits = _digitsOnly(trimmed);
    if (digits.isEmpty) return '';
    return 'https://wa.me/$digits';
  }
}

class _DetailKatalogPageState extends State<DetailKatalogPage> {
  final ProductsApi _productsApi = ProductsApi();

  late Map<String, dynamic> _product;
  bool _ratingSubmitting = false;
  int _myRating = 0;

  static String _myRatingKey(String productId) =>
      'product_my_rating_$productId';

  @override
  void initState() {
    super.initState();
    _product = Map<String, dynamic>.from(widget.product);
    _loadMyRating();
  }

  Future<void> _loadMyRating() async {
    final String id = (_product['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final int saved = prefs.getInt(_myRatingKey(id)) ?? 0;
      if (!mounted) return;
      setState(() {
        _myRating = saved.clamp(0, 5);
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _persistMyRating(String productId, int stars) async {
    final String id = productId.trim();
    if (id.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final int v = stars.clamp(0, 5);
      if (v <= 0) {
        await prefs.remove(_myRatingKey(id));
      } else {
        await prefs.setInt(_myRatingKey(id), v);
      }
    } catch (_) {
      // ignore
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> _submitRating(int stars) async {
    final String id = (_product['id'] ?? '').toString().trim();
    if (id.isEmpty) {
      AppNotify.show(
        context,
        'ID produk tidak ditemukan',
        type: AppNotifyType.error,
      );
      return;
    }

    if (_ratingSubmitting) return;

    final int safeStars = stars.clamp(1, 5);

    final String? token = await AuthStorage().getToken();
    if (!mounted) return;
    if (token == null || token.trim().isEmpty) {
      AppNotify.show(
        context,
        'Silakan login untuk memberi rating',
        type: AppNotifyType.info,
      );
      return;
    }

    setState(() {
      _ratingSubmitting = true;
    });

    try {
      final Map<String, dynamic>? updated = await _productsApi.rateProduct(
        id: id,
        rating: safeStars,
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _myRating = safeStars;
        if (updated != null) {
          _product = <String, dynamic>{..._product, ...updated};
        } else {
          // Fallback: update tampilan rating minimal.
          _product = <String, dynamic>{
            ..._product,
            'rating': safeStars.toDouble(),
          };
        }
      });

      await _persistMyRating(id, safeStars);

      if (!mounted) return;

      ProductsRefresh.bump();

      AppNotify.show(context, 'Rating tersimpan', type: AppNotifyType.success);
    } on DioException catch (e) {
      if (!mounted) return;
      final int? status = e.response?.statusCode;
      final dynamic data = e.response?.data;
      if (status == 401) {
        AppNotify.show(
          context,
          'Sesi login habis. Silakan login ulang.',
          type: AppNotifyType.info,
        );
      } else {
        String? serverMessage;
        if (data is Map) {
          final dynamic m = data['message'] ?? data['error'];
          if (m is String) serverMessage = m;
          if (serverMessage == null && m is List) {
            serverMessage = m.map((e) => e.toString()).join('\n');
          }
        } else if (data is String && data.trim().isNotEmpty) {
          serverMessage = data.trim();
        }

        AppNotify.show(
          context,
          (serverMessage != null && serverMessage.trim().isNotEmpty)
              ? serverMessage.trim()
              : 'Gagal mengirim rating. Coba lagi.',
          type: AppNotifyType.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppNotify.show(
        context,
        'Gagal mengirim rating. Coba lagi.',
        type: AppNotifyType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _ratingSubmitting = false;
        });
      }
    }
  }

  Widget _labelChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.brandGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.brandGreen,
        ),
      ),
    );
  }

  Widget _buildRatingPicker({required double currentRating}) {
    // Picker ini hanya menunjukkan pilihan user saat ini.
    // Nilai rating rata-rata produk tetap ditampilkan di bagian lain.
    final int filled = _myRating.clamp(0, 5);

    return Row(
      children: [
        const Text(
          'Beri rating:',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        const Spacer(),
        if (_ratingSubmitting)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        if (_ratingSubmitting) const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final int star = i + 1;
            final bool on = star <= filled;
            return InkWell(
              onTap: _ratingSubmitting
                  ? null
                  : () {
                      // Tap bintang yang sama 2x = batal (kosong lagi)
                      if (_myRating == star) {
                        setState(() {
                          _myRating = 0;
                        });
                        final String id = (_product['id'] ?? '')
                            .toString()
                            .trim();
                        _persistMyRating(id, 0);
                        return;
                      }
                      _submitRating(star);
                    },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  on ? Icons.star : Icons.star_border,
                  size: 20,
                  color: Colors.amber,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // Helper widget untuk bar rating
  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$star',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
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

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> product = _product;

    final String title = (product['title'] ?? product['name'] ?? '').toString();
    final String priceText = (product['price'] ?? '').toString();
    final String locationText = (product['location'] ?? '').toString();
    final String mapsLink = (product['mapsLink'] ?? '').toString();

    final String whatsappLink = (product['whatsappLink'] ?? '').toString();
    final String whatsappUrl = DetailKatalogPage.normalizeWhatsappToUrl(
      whatsappLink,
    );
    final String description = (product['description'] ?? '').toString();
    final String benefits = (product['benefits'] ?? '').toString();
    final String suitableFor = (product['suitableFor'] ?? '').toString();
    final String caution = (product['caution'] ?? '').toString();
    final int stock = _toInt(product['stock']);
    final int calories = _toInt(product['caloriesValue']);
    final String protein = (product['proteinValue'] ?? '').toString();
    final String fat = (product['fatValue'] ?? '').toString();
    final double ratingValue = _toDouble(product['rating']);

    final List<String> labels = DetailKatalogPage._firstTwoLabels(
      product['label'],
    );

    final String aboutText = [
      if (description.isNotEmpty) description,
      if (benefits.isNotEmpty) 'Manfaat: $benefits',
      if (suitableFor.isNotEmpty) 'Cocok untuk: $suitableFor',
      if (caution.isNotEmpty) 'Catatan: $caution',
      if (calories > 0) 'Kalori: $calories',
      if (protein.isNotEmpty) 'Protein: $protein',
      if (fat.isNotEmpty) 'Lemak: $fat',
    ].join('\n');

    final String stockLabel = stock > 0 ? 'Stok: $stock' : 'Stok Tersedia';

    final String? sellerId = DetailKatalogPage._extractUserId(product);
    final String sellerFallback = DetailKatalogPage._extractSellerFallback(
      product,
    );

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
                onPressed: () async {
                  final String t = title.trim();
                  if (t.isEmpty) {
                    AppNotify.show(
                      context,
                      'Produk tidak ditemukan untuk dibagikan.',
                      type: AppNotifyType.error,
                    );
                    return;
                  }

                  final String shareText = <String>[
                    'Tumbuh - $t',
                    if (priceText.trim().isNotEmpty)
                      'Harga: ${priceText.trim()}',
                    if (locationText.trim().isNotEmpty)
                      'Lokasi: ${locationText.trim()}',
                    if (mapsLink.trim().isNotEmpty) 'Maps: ${mapsLink.trim()}',
                    if (whatsappUrl.trim().isNotEmpty)
                      'WhatsApp: ${whatsappUrl.trim()}',
                  ].join('\n');

                  try {
                    final RenderObject? ro = context.findRenderObject();
                    final Rect? origin = ro is RenderBox
                        ? (ro.localToGlobal(Offset.zero) & ro.size)
                        : null;

                    await Share.share(
                      shareText,
                      subject: 'Produk: $t',
                      sharePositionOrigin: origin,
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    AppNotify.show(
                      context,
                      'Gagal membagikan produk. Coba lagi.',
                      type: AppNotifyType.error,
                    );
                  }
                },
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
          onPressed: () async {
            if (whatsappUrl.trim().isEmpty) {
              AppNotify.show(
                context,
                'Link WhatsApp belum tersedia',
                type: AppNotifyType.error,
              );
              return;
            }

            final Uri? uri = Uri.tryParse(whatsappUrl.trim());
            if (uri == null) {
              AppNotify.show(
                context,
                'Link WhatsApp tidak valid',
                type: AppNotifyType.error,
              );
              return;
            }

            final bool ok = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );

            if (!ok && context.mounted) {
              AppNotify.show(
                context,
                'Gagal membuka WhatsApp',
                type: AppNotifyType.error,
              );
            }
          },
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
                    errorBuilder: (_, __, ___) => Image.network(
                      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80',
                      height: 350,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ===== CONTENT SECTION =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Harga dan Tag (di bawah nama produk)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product['price'],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.brandGreen,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          stockLabel,
                          style: const TextStyle(
                            color: AppTheme.brandGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (labels.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: labels.map(_labelChip).toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 16),

                  // Info Penjual (Dibuat lebih menarik dengan Row)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE8E3D9),
                        child: Icon(Icons.store, color: AppTheme.brandGreen),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String?>(
                              future: (sellerFallback.trim().isNotEmpty)
                                  ? Future.value(null)
                                  : ((sellerId == null ||
                                            sellerId.trim().isEmpty)
                                        ? Future.value(null)
                                        : UsersApi().fetchDisplayNameById(
                                            sellerId.trim(),
                                          )),
                              builder: (context, snap) {
                                final String name =
                                    (snap.data ?? '').trim().isNotEmpty
                                    ? (snap.data ?? '').trim()
                                    : sellerFallback;

                                return Text(
                                  name.isNotEmpty ? name : 'Penjual',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${product['location']}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                    aboutText.isNotEmpty
                        ? aboutText
                        : 'Deskripsi belum tersedia.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.7),
                      height: 1.5,
                    ),
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
                                  ratingValue.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  '/ 5.0',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildRatingBar(
                                    5,
                                    0.9,
                                  ), // Contoh 90% bintang 5
                                  _buildRatingBar(4, 0.1),
                                  _buildRatingBar(3, 0.0),
                                  _buildRatingBar(2, 0.0),
                                  _buildRatingBar(1, 0.0),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildRatingPicker(currentRating: ratingValue),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 100,
                  ), // Spacer agar tidak tertutup button bawah
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
