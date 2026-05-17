import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';

class AppRoutes {
  static const shell = '/';
  static const login = '/login';
  static const register = '/register';

  static final routes = <String, WidgetBuilder>{
    shell: (_) => const AuthGate(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
  };
}
