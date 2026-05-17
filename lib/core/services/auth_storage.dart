import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _kLoggedIn = 'auth_logged_in';
  static const String _kToken = 'auth_token';
  static const String _kName = 'auth_name';
  static const String _kPhone = 'auth_phone';
  static const String _kShowPanduanAfterLogin = 'show_panduan_after_login';

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kLoggedIn) == true;
  }

  Future<void> saveLogin({String? token, String? name, String? phone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    if (token != null && token.trim().isNotEmpty) {
      await prefs.setString(_kToken, token.trim());
    }

    final String n = (name ?? '').trim();
    if (n.isNotEmpty) {
      await prefs.setString(_kName, n);
    }

    final String p = (phone ?? '').trim();
    if (p.isNotEmpty) {
      await prefs.setString(_kPhone, p);
    }
  }

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kName);
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kPhone);
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  Future<String> getDisplayName() async {
    final name = await getName();
    if (name != null && name.isNotEmpty) return name;
    final phone = await getPhone();
    if (phone != null && phone.isNotEmpty) return phone;
    return 'Pengguna';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null) return null;
    final t = token.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kName);
    await prefs.remove(_kPhone);
    await prefs.setBool(_kLoggedIn, false);
  }

  Future<void> markShowPanduanAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowPanduanAfterLogin, true);
  }

  /// Returns true once, then resets the flag to false.
  Future<bool> consumeShowPanduanAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final shouldShow = prefs.getBool(_kShowPanduanAfterLogin) == true;
    if (shouldShow) {
      await prefs.setBool(_kShowPanduanAfterLogin, false);
    }
    return shouldShow;
  }
}
