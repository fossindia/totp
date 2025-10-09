import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:totp/src/features/home/presentation/widgets/totp_card.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TotpCard Widget Tests', () {
    final testTotpItem = TotpItem(
      id: 'test-id',
      serviceName: 'TestService',
      username: 'test@example.com',
      secret: 'JBSWY3DPEHPK3PXP',
    );

    testWidgets('renders basic structure correctly', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: testTotpItem)),
        ),
      );

      // Assert - Basic structure should be present
      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('displays service name and username', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: testTotpItem)),
        ),
      );

      // Assert
      expect(find.text('TestService'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('displays category when provided', (WidgetTester tester) async {
      // Arrange
      final itemWithCategory = TotpItem(
        id: 'test-id',
        serviceName: 'TestService',
        username: 'test@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
        category: 'Work',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: itemWithCategory)),
        ),
      );

      // Assert
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('handles long service names gracefully', (
      WidgetTester tester,
    ) async {
      // Arrange
      final longNameItem = TotpItem(
        id: 'test-id',
        serviceName: 'Very Long Service Name That Should Be Handled Properly',
        username: 'test@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: longNameItem)),
        ),
      );

      // Assert
      expect(
        find.text('Very Long Service Name That Should Be Handled Properly'),
        findsOneWidget,
      );
    });

    testWidgets('applies correct card styling', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: testTotpItem)),
        ),
      );

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 0);
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('has proper padding and layout', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: testTotpItem)),
        ),
      );

      // Assert - Check for padding widget
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('contains circular progress indicator for timer', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: testTotpItem)),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('supports custom interval', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TotpCard(totpItem: testTotpItem, interval: 60)),
        ),
      );

      // Assert - Widget should build without errors
      expect(find.byType(TotpCard), findsOneWidget);
    });

    testWidgets('calls onEdit callback when provided', (
      WidgetTester tester,
    ) async {
      // Arrange
      bool callbackCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TotpCard(
              totpItem: testTotpItem,
              onEdit: () => callbackCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      // Assert
      expect(callbackCalled, isTrue);
    });

    testWidgets('handles null onEdit callback gracefully', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TotpCard(totpItem: testTotpItem), // No onEdit callback
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      // Assert - Should not crash
      expect(find.byType(TotpCard), findsOneWidget);
    });
  });
}
