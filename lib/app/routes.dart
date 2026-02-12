import 'package:flutter/material.dart';
import '../features/shell.dart';

class AppRoutes {
  static const shell = '/';

  static final routes = <String, WidgetBuilder>{
    shell: (_) => const AppShell(),
  };
}
