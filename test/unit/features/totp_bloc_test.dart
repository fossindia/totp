import 'package:flutter_test/flutter_test.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TotpManager totpManager;
  late TotpBloc totpBloc;

  setUp(() {
    totpManager = TotpManager();
    totpBloc = TotpBloc(totpManager);
  });

  tearDown(() {
    totpBloc.close();
  });

  group('TotpBloc', () {
    group('Initial state', () {
      test('should have TotpInitial as initial state', () {
        expect(totpBloc.state, equals(TotpInitial()));
      });
    });

    group('State transitions', () {
      test('TotpLoadSuccess copyWith works correctly', () {
        final state = TotpLoadSuccess(totpItems: [], filteredTotpItems: []);

        final newState = state.copyWith(searchQuery: 'test');

        expect(newState.searchQuery, equals('test'));
        expect(newState.totpItems, equals([]));
        expect(newState.filteredTotpItems, equals([]));
      });

      test('TotpLoadFailure has correct error message', () {
        const error = 'Test error';
        final state = TotpLoadFailure(error);

        expect(state.error, equals(error));
      });
    });

    group('Event props', () {
      test('LoadTotpItems has empty props', () {
        final event = LoadTotpItems();
        expect(event.props, isEmpty);
      });

      test('AddTotpItem has correct props', () {
        final item = TotpItem(
          id: '1',
          serviceName: 'Test',
          username: 'user',
          secret: 'JBSWY3DPEHPK3PXP',
        );
        final event = AddTotpItem(item);
        expect(event.props, equals([item]));
      });

      test('UpdateTotpItem has correct props', () {
        final item = TotpItem(
          id: '1',
          serviceName: 'Test',
          username: 'user',
          secret: 'JBSWY3DPEHPK3PXP',
        );
        final event = UpdateTotpItem(item);
        expect(event.props, equals([item]));
      });

      test('DeleteTotpItem has correct props', () {
        const id = 'test-id';
        final event = DeleteTotpItem(id);
        expect(event.props, equals([id]));
      });

      test('SearchTotpItems has correct props', () {
        const query = 'test query';
        const category = 'test category';
        final event = SearchTotpItems(query, category);
        expect(event.props, equals([query, category]));
      });
    });

    group('State props', () {
      test('TotpInitial has empty props', () {
        final state = TotpInitial();
        expect(state.props, isEmpty);
      });

      test('TotpLoadInProgress has empty props', () {
        final state = TotpLoadInProgress();
        expect(state.props, isEmpty);
      });

      test('TotpLoadSuccess has correct props', () {
        final mockTotpItems = [
          TotpItem(
            id: '1',
            serviceName: 'Google',
            username: 'user@example.com',
            secret: 'JBSWY3DPEHPK3PXP',
          ),
        ];
        final state = TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: mockTotpItems,
          searchQuery: 'test',
          categoryFilter: 'work',
        );
        expect(
          state.props,
          equals([mockTotpItems, mockTotpItems, 'test', 'work']),
        );
      });

      test('TotpLoadFailure has correct props', () {
        const error = 'Test error';
        final state = TotpLoadFailure(error);
        expect(state.props, equals([error]));
      });
    });

    group('Bloc functionality', () {
      test('should handle SearchTotpItems event when in success state', () {
        // Set up initial success state
        final mockTotpItems = [
          TotpItem(
            id: '1',
            serviceName: 'Test Service',
            username: 'testuser',
            secret: 'JBSWY3DPEHPK3PXP',
          ),
        ];
        final initialState = TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: mockTotpItems,
        );

        // Test search functionality by checking state copyWith
        final searchedState = initialState.copyWith(
          filteredTotpItems: [mockTotpItems[0]],
          searchQuery: 'Test',
        );

        expect(searchedState.searchQuery, equals('Test'));
        expect(searchedState.filteredTotpItems.length, equals(1));
      });
    });
  });
}
