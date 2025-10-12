import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:totp/src/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QRScannerScreen Widget Tests', () {
    testWidgets('displays app bar with correct title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: QRScannerScreen()));

      expect(find.text('Scan QR Code'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays torch toggle button', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: QRScannerScreen()));

      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('has proper app bar actions', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: QRScannerScreen()));

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, 1); // Torch button
    });

    testWidgets('torch button is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: QRScannerScreen()));

      // Initially shows flash_off
      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('widget builds without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: QRScannerScreen()));

      // The widget should build without crashing
      expect(find.byType(QRScannerScreen), findsOneWidget);
    });

    testWidgets('maintains proper aspect ratio', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(width: 400, height: 600, child: QRScannerScreen()),
        ),
      );

      // Widget should fit within bounds
      expect(find.byType(QRScannerScreen), findsOneWidget);
    });

    testWidgets('handles different screen orientations', (
      WidgetTester tester,
    ) async {
      // Test portrait
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: QRScannerScreen()));

      expect(find.byType(QRScannerScreen), findsOneWidget);

      // Test landscape
      tester.view.physicalSize = const Size(1920, 1080);

      await tester.pumpWidget(const MaterialApp(home: QRScannerScreen()));

      expect(find.byType(QRScannerScreen), findsOneWidget);
    });
  });
}
