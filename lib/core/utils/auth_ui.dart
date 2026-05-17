import 'package:flutter/material.dart';
import 'package:tumbuh_app/app/routes.dart';
import 'package:tumbuh_app/core/services/auth_storage.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );

  if (ok != true) return;

  await AuthStorage().logout();
  if (!context.mounted) return;
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRoutes.shell, (route) => false);
}
