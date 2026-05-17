import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/recipe_likes_storage.dart';
import 'package:tumbuh_app/core/utils/app_notify.dart';
import 'package:tumbuh_app/core/services/recipes_api.dart';
import 'package:url_launcher/url_launcher.dart';

part 'detail/detailresep_types.dart';
part 'detail/detailresep_helpers.dart';
part 'detail/detailresep_hero_section.dart';
part 'detail/detailresep_nutrition_section.dart';
part 'detail/detailresep_ingredients_tools_section.dart';
part 'detail/detailresep_cooking_section.dart';

class DetailResepPage extends StatefulWidget {
  final Map<String, dynamic>? recipe;
  final bool initiallyLiked;
  const DetailResepPage({super.key, this.recipe, this.initiallyLiked = false});

  @override
  State<DetailResepPage> createState() => _DetailResepPageState();
}

class _DetailResepPageState extends State<DetailResepPage> {
  bool _liked = false;
  bool _busy = false;

  Map<String, dynamic> get _r => widget.recipe ?? const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _liked = widget.initiallyLiked;
    _hydrateLiked();
  }

  Future<void> _hydrateLiked() async {
    final String id = (_r['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    final storage = RecipeLikesStorage();

    // Local cache wins (keeps the button stable when reopening).
    final bool? cached = await storage.getLiked(id);
    if (!mounted) return;
    if (cached != null) {
      if (cached != _liked) {
        setState(() {
          _liked = cached;
        });
      }
      return;
    }

    // If we don't have cache yet, try server liked list (best effort).
    try {
      final likedItems = await RecipesApi().fetchLikedRecipesMe();
      final bool isLiked = likedItems.any(
        (e) => (e['id'] ?? '').toString().trim() == id,
      );
      await storage.setLiked(id, isLiked);
      if (!mounted) return;
      if (isLiked != _liked) {
        setState(() {
          _liked = isLiked;
        });
      }
    } catch (_) {
      // Ignore: not logged in / offline / endpoint failed.
    }
  }

  Future<void> _toggleLike() async {
    if (_busy) return;
    final String id = (_r['id'] ?? '').toString().trim();
    if (id.isEmpty) {
      AppNotify.show(
        context,
        'ID resep tidak ditemukan',
        type: AppNotifyType.error,
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      // Backend uses a single toggle endpoint: calling like twice will unlike.
      final bool wasLiked = _liked;
      await RecipesApi().likeRecipe(id);
      if (!mounted) return;

      setState(() {
        _liked = !wasLiked;
      });

      await RecipeLikesStorage().setLiked(id, _liked);
      if (!mounted) return;

      AppNotify.show(
        context,
        wasLiked ? 'Batal menyukai resep' : 'Resep berhasil disukai',
        type: wasLiked ? AppNotifyType.info : AppNotifyType.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppNotify.show(
        context,
        _liked ? 'Gagal batal menyukai resep' : 'Gagal menyukai resep',
        type: AppNotifyType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImageSection(
              r: _r,
              isLiked: _liked,
              isBusy: _busy,
              onLike: _toggleLike,
            ),
            _NutritionInfoSection(r: _r),
            const SizedBox(height: 16),
            _IngredientsToolsSection(r: _r),
            const SizedBox(height: 16),
            _CookingStepsSection(r: _r),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
