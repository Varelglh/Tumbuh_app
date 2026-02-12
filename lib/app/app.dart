import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class TumbuhApp extends StatelessWidget {
  const TumbuhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tumbuh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.shell,
    );
  }
}
