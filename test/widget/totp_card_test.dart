import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:totp/src/features/home/presentation/widgets/totp_card.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/core/services/settings_service.dart';
import 'package:totp/src/features/totp_generation/totp_service.dart';
import 'package:totp/src/core/di/service_locator.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';

// Generate mocks
@GenerateMocks([SettingsService, TotpService, TotpBloc])
import 'totp_card_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSettingsService mockSettingsService;
  late MockTotpService mockTotpService;
  late MockTotpBloc mockTotpBloc;

  setUp(() {
    mockSettingsService = MockSettingsService();
    mockTotpService = MockTotpService();
    mockTotpBloc = MockTotpBloc();

    // Mock the service methods
    when(mockSettingsService.getCopyTotpOnTap()).thenReturn(true);
    when(
      mockTotpService.generateTotp(any, interval: anyNamed('interval')),
    ).thenReturn('123456');
    when(
      mockTotpService.getRemainingSeconds(interval: anyNamed('interval')),
    ).thenReturn(25);

    // Mock BLoC state
    when(
      mockTotpBloc.state,
    ).thenReturn(TotpLoadSuccess(totpItems: [], filteredTotpItems: []));
    when(mockTotpBloc.stream).thenAnswer(
      (_) =>
          Stream.value(TotpLoadSuccess(totpItems: [], filteredTotpItems: [])),
    );

    // Register mocks in service locator
    ServiceLocator.register<SettingsService>(mockSettingsService);
    ServiceLocator.register<TotpService>(mockTotpService);
  });

  tearDown(() {
    ServiceLocator.reset();
  });

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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(body: TotpCard(totpItem: testTotpItem)),
          ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(body: TotpCard(totpItem: testTotpItem)),
          ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(body: TotpCard(totpItem: itemWithCategory)),
          ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(body: TotpCard(totpItem: longNameItem)),
          ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(body: TotpCard(totpItem: testTotpItem)),
          ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(body: TotpCard(totpItem: testTotpItem)),
          ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(body: TotpCard(totpItem: testTotpItem)),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('supports custom interval', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(
              body: TotpCard(totpItem: testTotpItem, interval: 60),
            ),
          ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(
              body: TotpCard(
                totpItem: testTotpItem,
                onEdit: () => callbackCalled = true,
              ),
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
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: Scaffold(
              body: TotpCard(totpItem: testTotpItem), // No onEdit callback
            ),
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
