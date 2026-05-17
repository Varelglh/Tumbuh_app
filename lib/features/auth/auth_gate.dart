import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/theme.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';
import 'package:tumbuh_app/features/auth/login_page.dart';
import 'package:tumbuh_app/features/shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthStorage().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppTheme.cream,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.brandGreen),
            ),
          );
        }

        final loggedIn = snapshot.data == true;
        return loggedIn ? const AppShell() : const LoginPage();
      },
    );
  }
}
