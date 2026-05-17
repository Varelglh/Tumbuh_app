import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tumbuh_app/features/scan/scan.dart';

void main() {
  test('matchSupportedScanIngredient hanya menerima bahan yang didukung', () {
    expect(matchSupportedScanIngredient('ayam'), 'ayam');
    expect(matchSupportedScanIngredient('Egg'), 'telur');
    expect(matchSupportedScanIngredient('purple_eggplant'), 'terong ungu');
    expect(matchSupportedScanIngredient('ikan'), isNull);
    expect(matchSupportedScanIngredient(''), isNull);
  });

  testWidgets('ScanPage menampilkan note bahan scan dan status awal belum dikenali', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScanPage(
          scanner: SizedBox.expand(),
        ),
      ),
    );

    expect(find.text('Pindai Makanan'), findsOneWidget);
    expect(find.text('Bahan yang bisa di-scan'), findsOneWidget);
    expect(find.text('Ayam'), findsOneWidget);
    expect(find.text('Telur'), findsOneWidget);
    expect(find.text('Kentang'), findsOneWidget);
    expect(find.text('Tempe'), findsOneWidget);
    expect(find.text('Jagung'), findsOneWidget);
    expect(find.text('Terong Ungu'), findsOneWidget);
    expect(find.text('Bahan belum dikenali'), findsOneWidget);
  });
}
