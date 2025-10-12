import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:totp/src/features/home/presentation/widgets/totp_list.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/core/services/settings_service.dart';
import 'package:totp/src/core/di/service_locator.dart';

// Generate mocks
@GenerateMocks([TotpBloc, SettingsService])
import 'totp_list_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTotpBloc mockTotpBloc;
  late MockSettingsService mockSettingsService;

  setUp(() {
    mockTotpBloc = MockTotpBloc();
    mockSettingsService = MockSettingsService();

    // Mock the service methods
    when(mockSettingsService.getTotpRefreshInterval()).thenReturn(30);

    // Mock BLoC stream
    when(mockTotpBloc.stream).thenAnswer(
      (_) =>
          Stream.value(TotpLoadSuccess(totpItems: [], filteredTotpItems: [])),
    );

    // Register mocks in service locator
    ServiceLocator.register<SettingsService>(mockSettingsService);
  });

  tearDown(() {
    ServiceLocator.reset();
  });

  group('TotpList Widget Tests', () {
    final testTotpItems = [
      TotpItem(
        id: '1',
        serviceName: 'Google',
        username: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
        category: 'Work',
      ),
      TotpItem(
        id: '2',
        serviceName: 'GitHub',
        username: 'user',
        secret: 'JBSWY3DPEHPK3PXQ',
        category: 'Development',
      ),
    ];

    testWidgets('displays loading indicator when in loading state', (
      WidgetTester tester,
    ) async {
      when(mockTotpBloc.state).thenReturn(TotpLoadInProgress());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when in error state', (
      WidgetTester tester,
    ) async {
      const errorMessage = 'Failed to load items';
      when(mockTotpBloc.state).thenReturn(TotpLoadFailure(errorMessage));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays empty state when no items', (
      WidgetTester tester,
    ) async {
      when(
        mockTotpBloc.state,
      ).thenReturn(TotpLoadSuccess(totpItems: [], filteredTotpItems: []));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(true),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.text('No accounts found'), findsOneWidget);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    });

    testWidgets('displays TOTP items correctly', (WidgetTester tester) async {
      when(mockTotpBloc.state).thenReturn(
        TotpLoadSuccess(
          totpItems: testTotpItems,
          filteredTotpItems: testTotpItems,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
    });

    testWidgets('filters items by category', (WidgetTester tester) async {
      when(mockTotpBloc.state).thenReturn(
        TotpLoadSuccess(
          totpItems: testTotpItems,
          filteredTotpItems: [testTotpItems[0]], // Only Work category
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: 'Work',
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('GitHub'), findsNothing); // Should be filtered out
    });

    testWidgets('handles search query changes', (WidgetTester tester) async {
      final searchController = TextEditingController(text: 'google');
      final searchNotifier = ValueNotifier<String>('google');

      when(mockTotpBloc.state).thenReturn(
        TotpLoadSuccess(
          totpItems: testTotpItems,
          filteredTotpItems: [testTotpItems[0]],
          searchQuery: 'google',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: searchController,
              searchQueryNotifier: searchNotifier,
            ),
          ),
        ),
      );

      expect(find.text('Google'), findsOneWidget);
      expect(find.text('GitHub'), findsNothing);
    });

    testWidgets('uses ListView for rendering items', (
      WidgetTester tester,
    ) async {
      when(mockTotpBloc.state).thenReturn(
        TotpLoadSuccess(
          totpItems: testTotpItems,
          filteredTotpItems: testTotpItems,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('applies proper padding and spacing', (
      WidgetTester tester,
    ) async {
      when(mockTotpBloc.state).thenReturn(
        TotpLoadSuccess(
          totpItems: testTotpItems,
          filteredTotpItems: testTotpItems,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      // Check for padding widgets
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('handles state changes correctly', (WidgetTester tester) async {
      when(mockTotpBloc.state).thenReturn(TotpLoadInProgress());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Change state to success
      when(mockTotpBloc.state).thenReturn(
        TotpLoadSuccess(
          totpItems: testTotpItems,
          filteredTotpItems: testTotpItems,
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('displays categories when available', (
      WidgetTester tester,
    ) async {
      when(mockTotpBloc.state).thenReturn(
        TotpLoadSuccess(
          totpItems: testTotpItems,
          filteredTotpItems: testTotpItems,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TotpBloc>.value(
            value: mockTotpBloc,
            child: TotpList(
              isEmptyNotifier: ValueNotifier<bool>(false),
              categoryFilter: null,
              searchController: TextEditingController(),
              searchQueryNotifier: ValueNotifier<String>(''),
            ),
          ),
        ),
      );

      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Development'), findsOneWidget);
    });
  });
}
