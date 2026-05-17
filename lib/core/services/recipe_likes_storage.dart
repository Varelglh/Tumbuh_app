import 'package:shared_preferences/shared_preferences.dart';

class RecipeLikesStorage {
  static const String _kPrefix = 'recipe_liked_';

  String _keyFor(String recipeId) =>
      '$_kPrefix${Uri.encodeComponent(recipeId)}';

  Future<bool?> getLiked(String recipeId) async {
    final String id = recipeId.trim();
    if (id.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(id));
  }

  Future<void> setLiked(String recipeId, bool liked) async {
    final String id = recipeId.trim();
    if (id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(id), liked);
  }
}
