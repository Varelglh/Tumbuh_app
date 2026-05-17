import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/routes.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/auth_api.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/core/services/users_api.dart';
import 'package:tumbuh_app/core/utils/app_notify.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameC = TextEditingController();
  final _passC = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final username = _usernameC.text.trim();
    final pass = _passC.text;

    if (username.isEmpty || pass.isEmpty) {
      AppNotify.show(
        context,
        'Username & kata sandi wajib diisi',
        type: AppNotifyType.error,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await AuthApi().login(username: username, password: pass);
      await AuthStorage().saveLogin(
        token: res.token,
        name: res.name ?? username,
        phone: res.phoneNumber,
      );

      // Fallback: some backends don't include phoneNumber on /auth/login.
      // Try fetching it from a profile endpoint using the token.
      final String token = (res.token ?? '').trim();
      final String phone = (res.phoneNumber ?? '').trim();
      if (token.isNotEmpty && phone.isEmpty) {
        final fetchedPhone = await UsersApi().fetchMyPhone(token: token);
        if (fetchedPhone != null && fetchedPhone.trim().isNotEmpty) {
          await AuthStorage().saveLogin(phone: fetchedPhone.trim());
        } else {
          final String? userId = UsersApi.extractUserIdFromJwt(token);
          if (userId != null && userId.trim().isNotEmpty) {
            final byId = await UsersApi().fetchPhoneById(
              token: token,
              userId: userId.trim(),
            );
            if (byId != null && byId.trim().isNotEmpty) {
              await AuthStorage().saveLogin(phone: byId.trim());
            }
          }
        }
      }

      await AuthStorage().markShowPanduanAfterLogin();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.shell, (route) => false);
    } catch (e) {
      if (!mounted) return;
      final msg = AuthApi.extractErrorMessage(e);
      AppNotify.show(context, msg, type: AppNotifyType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Image.asset('assets/icons/app_icon.png', width: 90),
                            const SizedBox(height: 10),
                            const Text(
                              'Tumbuh',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.brandGreen,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Masuk ke Akun Anda',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _field(
                        icon: Icons.person_outline,
                        hint: 'Username',
                        controller: _usernameC,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 10),
                      _field(
                        icon: Icons.lock_outline,
                        hint: 'Kata Sandi',
                        controller: _passC,
                        obscureText: _obscure,
                        suffix: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.register),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.brandGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, size: 18, color: Colors.black38),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppTheme.brandGreen),
        ),
      ),
    );
  }
}
