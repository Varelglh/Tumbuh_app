// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:tumbuh_app/app/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(const TumbuhApp());
      // Avoid pumpAndSettle here because some screens may keep animating
      // (e.g. progress indicators), which would cause timeouts.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Basic sanity checks: app renders and has at least one Scaffold.
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
