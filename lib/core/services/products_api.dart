import 'package:dio/dio.dart';

import 'api_client.dart';

class ProductsApi {
  ProductsApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  static const String _fallbackImageUrl =
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=1200&q=80';

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final Response<dynamic> res = await _client.dio.get('/products');
    final dynamic body = res.data;

    final List<dynamic> items;
    if (body is Map<String, dynamic> && body['data'] is List) {
      items = body['data'] as List<dynamic>;
    } else if (body is List) {
      items = body;
    } else {
      throw const FormatException('Unexpected /products response shape');
    }

    return items.map(_mapProduct).toList();
  }

  Future<Map<String, dynamic>> createProduct({
    required String token,
    required String name,
    required String description,
    required String label,
    required String category,
    required num price,
    required String location,
    required String whatsappLink,
    required int stock,
    required String imagePath,
    String? imageFileName,
  }) async {
    final FormData form = FormData.fromMap(<String, dynamic>{
      'name': name,
      'description': description,
      'label': label,
      'category': category,
      'price': price,
      'location': location,
      'whatsappLink': whatsappLink,
      'stock': stock,
      'image': await MultipartFile.fromFile(
        imagePath,
        filename: (imageFileName == null || imageFileName.trim().isEmpty)
            ? null
            : imageFileName.trim(),
      ),
    });

    final Response<dynamic> res = await _client.dio.post(
      '/products',
      data: form,
      options: Options(
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    final dynamic body = res.data;
    dynamic item;

    if (body is Map<String, dynamic>) {
      item = body['data'] ?? body['product'] ?? body;
    } else {
      item = body;
    }

    return _mapProduct(item);
  }

  Future<Map<String, dynamic>> updateProduct({
    required String id,
    required String token,
    required String name,
    required String description,
    required String label,
    required String category,
    required num price,
    required String location,
    required String whatsappLink,
    required int stock,
    String? imagePath,
    String? imageFileName,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'name': name,
      'description': description,
      'label': label,
      'category': category,
      'price': price,
      'location': location,
      'whatsappLink': whatsappLink,
      'stock': stock,
    };

    final Object data;
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      data = FormData.fromMap(<String, dynamic>{
        ...payload,
        'image': await MultipartFile.fromFile(
          imagePath,
          filename: (imageFileName == null || imageFileName.trim().isEmpty)
              ? null
              : imageFileName.trim(),
        ),
      });
    } else {
      // Without image change, send JSON to maximize backend compatibility.
      data = payload;
    }

    final Response<dynamic> res = await _client.dio.put(
      '/products/$id',
      data: data,
      options: Options(
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    final dynamic body = res.data;
    dynamic item;

    if (body is Map<String, dynamic>) {
      item = body['data'] ?? body['product'] ?? body;
    } else {
      item = body;
    }

    return _mapProduct(item);
  }

  Future<void> deleteProduct({
    required String id,
    required String token,
  }) async {
    await _client.dio.delete(
      '/products/$id',
      options: Options(
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> rateProduct({
    required String id,
    required int rating,
    String? token,
  }) async {
    final int safeRating = rating.clamp(1, 5);

    final Map<String, dynamic> headers = <String, dynamic>{
      'Accept': 'application/json',
    };
    final String tokenValue = (token ?? '').trim();
    if (tokenValue.isNotEmpty) {
      headers['Authorization'] = 'Bearer $tokenValue';
    }

    final Response<dynamic> res = await _client.dio.post(
      '/products/$id/rate',
      // Backend expects: { "score": 1..5 }
      data: <String, dynamic>{'score': safeRating},
      options: Options(headers: headers),
    );

    final dynamic body = res.data;
    dynamic item;

    if (body is Map<String, dynamic>) {
      item = body['data'] ?? body['product'] ?? body;
    } else {
      item = body;
    }

    if (item is Map || item is Map<String, dynamic>) {
      return _mapProduct(item);
    }

    return null;
  }

  Map<String, dynamic> _mapProduct(dynamic raw) {
    final Map<String, dynamic> m = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
              ? raw.map((k, v) => MapEntry('$k', v))
              : <String, dynamic>{});

    final String id = (m['id'] ?? '').toString();
    final String name = (m['name'] ?? '').toString();
    final String description = (m['description'] ?? '').toString();
    final String label = (m['label'] ?? '').toString();
    final String category = (m['category'] ?? '').toString();
    final String location = (m['location'] ?? '').toString();
    final dynamic seller = m['seller'];
    final String sellerIdFromObj = (seller is Map)
        ? (seller['id'] ?? seller['_id'] ?? seller['userId'] ?? '').toString()
        : '';
    final String sellerUsernameFromObj = (seller is Map)
        ? (seller['username'] ?? seller['userName'] ?? '').toString()
        : '';

    final String userId = (sellerIdFromObj.trim().isNotEmpty
        ? sellerIdFromObj
        : (m['userId'] ?? m['user_id'] ?? m['sellerId'] ?? m['ownerId'] ?? '')
              .toString());

    final String sellerName = (sellerUsernameFromObj.trim().isNotEmpty
        ? sellerUsernameFromObj
        : (m['sellerName'] ??
                  m['userName'] ??
                  m['user']?['name'] ??
                  m['user']?['fullName'] ??
                  m['user']?['username'] ??
                  '')
              .toString());

    final String mapsLink = (m['mapsLink'] ?? '').toString();
    final String whatsappLink = (m['whatsappLink'] ?? '').toString();

    final String imageUrl = (m['imageUrl'] ?? '').toString();
    final String priceDisplay = _formatRupiah(m['price']);

    final double rating = _toDouble(m['rating']) ?? 0.0;
    final int reviewCount =
        _toInt(m['reviewCount'] ?? m['reviews'] ?? m['review_count']) ?? 0;
    final int stock = _toInt(m['stock']) ?? 0;
    final String benefits = (m['benefits'] ?? '').toString();
    final String suitableFor = (m['suitableFor'] ?? '').toString();
    final String caution = (m['caution'] ?? '').toString();
    final int caloriesValue = _toInt(m['caloriesValue']) ?? 0;
    final String proteinValue = (m['proteinValue'] ?? '').toString();
    final String fatValue = (m['fatValue'] ?? '').toString();
    final String status = (m['status'] ?? '').toString();
    final String createdAt = (m['createdAt'] ?? '').toString();
    final String updatedAt = (m['updatedAt'] ?? '').toString();

    // Kunci untuk UI existing (Home/Katalog lama)
    final String title = name;
    final String author = label;

    return <String, dynamic>{
      // Raw-ish fields from API
      'id': id,
      'name': name,
      'description': description,
      'label': label,
      'category': category,
      'userId': userId,
      'sellerName': sellerName,
      'seller': seller,
      'location': location,
      'mapsLink': mapsLink,
      'whatsappLink': whatsappLink,
      'imageUrl': _sanitizeImageUrl(imageUrl),
      'priceRaw': m['price'],
      'price': priceDisplay,
      'rating': rating,
      'reviewCount': reviewCount,
      'reviews': reviewCount,
      'stock': stock,
      'benefits': benefits,
      'suitableFor': suitableFor,
      'caution': caution,
      'caloriesValue': caloriesValue,
      'proteinValue': proteinValue,
      'fatValue': fatValue,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,

      // Back-compat keys used in some widgets
      'title': title,
      'author': author,
      'image': _sanitizeImageUrl(imageUrl),
    };
  }

  static String _sanitizeImageUrl(String url) {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return _fallbackImageUrl;

    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return _fallbackImageUrl;
    }

    // Banyak backend mengisi contoh "https://link-foto.com/..." (sertifikat sering tidak valid).
    // Kalau kamu sudah pakai hosting gambar yang valid, URL akan dipakai apa adanya.
    final String host = uri.host.toLowerCase();
    if (host.contains('link-foto.com')) {
      return _fallbackImageUrl;
    }

    return trimmed;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static String _formatRupiah(dynamic raw) {
    if (raw == null) return 'Rp.0';
    final String s = raw.toString().trim();
    if (s.isEmpty) return 'Rp.0';
    if (s.toLowerCase().contains('rp')) return s;

    final double? parsed = double.tryParse(s);
    if (parsed == null) return s;

    final int value = parsed.round();
    final String digits = value.toString();
    final StringBuffer out = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int remaining = digits.length - i;
      out.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        out.write('.');
      }
    }

    return 'Rp.${out.toString()}';
  }
}
