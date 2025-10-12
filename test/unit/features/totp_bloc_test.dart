import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

// Generate mocks
@GenerateMocks([TotpManager])
import 'totp_bloc_test.mocks.dart';

void main() {
  late TotpBloc totpBloc;
  late MockTotpManager mockTotpManager;

  setUp(() {
    mockTotpManager = MockTotpManager();
    totpBloc = TotpBloc(mockTotpManager);
  });

  tearDown(() {
    totpBloc.close();
  });

  group('TotpBloc - Initial State', () {
    test('should have TotpInitial as initial state', () {
      expect(totpBloc.state, isA<TotpInitial>());
    });
  });

  group('TotpBloc - LoadTotpItems Event', () {
    final mockTotpItems = [
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

    blocTest<TotpBloc, TotpState>(
      'should emit [TotpLoadInProgress, TotpLoadSuccess] when loading succeeds',
      build: () {
        when(
          mockTotpManager.loadTotpItems(),
        ).thenAnswer((_) async => mockTotpItems);
        return totpBloc;
      },
      act: (bloc) => bloc.add(LoadTotpItems()),
      expect: () => [
        TotpLoadInProgress(),
        TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: mockTotpItems,
        ),
      ],
      verify: (_) {
        verify(mockTotpManager.loadTotpItems()).called(1);
      },
    );

    blocTest<TotpBloc, TotpState>(
      'should emit [TotpLoadInProgress, TotpLoadFailure] when loading fails',
      build: () {
        when(
          mockTotpManager.loadTotpItems(),
        ).thenThrow(Exception('Storage error'));
        return totpBloc;
      },
      act: (bloc) => bloc.add(LoadTotpItems()),
      expect: () => [
        TotpLoadInProgress(),
        TotpLoadFailure('Failed to load TOTP items'),
      ],
      verify: (_) {
        verify(mockTotpManager.loadTotpItems()).called(1);
      },
    );

    blocTest<TotpBloc, TotpState>(
      'should emit empty list when no items exist',
      build: () {
        when(mockTotpManager.loadTotpItems()).thenAnswer((_) async => []);
        return totpBloc;
      },
      act: (bloc) => bloc.add(LoadTotpItems()),
      expect: () => [
        TotpLoadInProgress(),
        TotpLoadSuccess(totpItems: [], filteredTotpItems: []),
      ],
    );
  });

  group('TotpBloc - AddTotpItem Event', () {
    final newTotpItem = TotpItem(
      id: '3',
      serviceName: 'Amazon',
      username: 'user@amazon.com',
      secret: 'JBSWY3DPEHPK3PXR',
      category: 'Shopping',
    );

    final existingItems = [
      TotpItem(
        id: '1',
        serviceName: 'Google',
        username: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      ),
    ];

    final updatedItems = [...existingItems, newTotpItem];

    blocTest<TotpBloc, TotpState>(
      'should add item and reload list when successful',
      build: () {
        when(mockTotpManager.addTotpItem(newTotpItem)).thenAnswer((_) async {});
        when(
          mockTotpManager.loadTotpItems(),
        ).thenAnswer((_) async => updatedItems);
        return totpBloc;
      },
      act: (bloc) => bloc.add(AddTotpItem(newTotpItem)),
      expect: () => [
        TotpLoadInProgress(),
        TotpLoadSuccess(
          totpItems: updatedItems,
          filteredTotpItems: updatedItems,
        ),
      ],
      verify: (_) {
        verify(mockTotpManager.addTotpItem(newTotpItem)).called(1);
        verify(mockTotpManager.loadTotpItems()).called(1);
      },
    );

    blocTest<TotpBloc, TotpState>(
      'should emit TotpLoadFailure when adding fails',
      build: () {
        when(
          mockTotpManager.addTotpItem(newTotpItem),
        ).thenThrow(Exception('Add failed'));
        return totpBloc;
      },
      act: (bloc) => bloc.add(AddTotpItem(newTotpItem)),
      expect: () => [TotpLoadFailure('Failed to add TOTP item')],
      verify: (_) {
        verify(mockTotpManager.addTotpItem(newTotpItem)).called(1);
      },
    );
  });

  group('TotpBloc - UpdateTotpItem Event', () {
    final updatedItem = TotpItem(
      id: '1',
      serviceName: 'Google Updated',
      username: 'user@example.com',
      secret: 'JBSWY3DPEHPK3PXP',
      category: 'Work',
    );

    final _ = [
      TotpItem(
        id: '1',
        serviceName: 'Google',
        username: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      ),
    ];

    blocTest<TotpBloc, TotpState>(
      'should update item and reload list when successful',
      build: () {
        when(
          mockTotpManager.updateTotpItem(updatedItem),
        ).thenAnswer((_) async {});
        when(
          mockTotpManager.loadTotpItems(),
        ).thenAnswer((_) async => [updatedItem]);
        return totpBloc;
      },
      act: (bloc) => bloc.add(UpdateTotpItem(updatedItem)),
      expect: () => [
        TotpLoadInProgress(),
        TotpLoadSuccess(
          totpItems: [updatedItem],
          filteredTotpItems: [updatedItem],
        ),
      ],
      verify: (_) {
        verify(mockTotpManager.updateTotpItem(updatedItem)).called(1);
        verify(mockTotpManager.loadTotpItems()).called(1);
      },
    );

    blocTest<TotpBloc, TotpState>(
      'should emit TotpLoadFailure when updating fails',
      build: () {
        when(
          mockTotpManager.updateTotpItem(updatedItem),
        ).thenThrow(Exception('Update failed'));
        return totpBloc;
      },
      act: (bloc) => bloc.add(UpdateTotpItem(updatedItem)),
      expect: () => [TotpLoadFailure('Failed to update TOTP item')],
      verify: (_) {
        verify(mockTotpManager.updateTotpItem(updatedItem)).called(1);
      },
    );
  });

  group('TotpBloc - DeleteTotpItem Event', () {
    const itemId = '1';
    final remainingItems = [
      TotpItem(
        id: '2',
        serviceName: 'GitHub',
        username: 'user',
        secret: 'JBSWY3DPEHPK3PXQ',
      ),
    ];

    blocTest<TotpBloc, TotpState>(
      'should delete item and reload list when successful',
      build: () {
        when(mockTotpManager.deleteTotpItem(itemId)).thenAnswer((_) async {});
        when(
          mockTotpManager.loadTotpItems(),
        ).thenAnswer((_) async => remainingItems);
        return totpBloc;
      },
      act: (bloc) => bloc.add(DeleteTotpItem(itemId)),
      expect: () => [
        TotpLoadInProgress(),
        TotpLoadSuccess(
          totpItems: remainingItems,
          filteredTotpItems: remainingItems,
        ),
      ],
      verify: (_) {
        verify(mockTotpManager.deleteTotpItem(itemId)).called(1);
        verify(mockTotpManager.loadTotpItems()).called(1);
      },
    );

    blocTest<TotpBloc, TotpState>(
      'should emit TotpLoadFailure when deleting fails',
      build: () {
        when(
          mockTotpManager.deleteTotpItem(itemId),
        ).thenThrow(Exception('Delete failed'));
        return totpBloc;
      },
      act: (bloc) => bloc.add(DeleteTotpItem(itemId)),
      expect: () => [TotpLoadFailure('Failed to delete TOTP item')],
      verify: (_) {
        verify(mockTotpManager.deleteTotpItem(itemId)).called(1);
      },
    );
  });

  group('TotpBloc - SearchTotpItems Event', () {
    final mockTotpItems = [
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
      TotpItem(
        id: '3',
        serviceName: 'Amazon',
        username: 'user@amazon.com',
        secret: 'JBSWY3DPEHPK3PXR',
        category: 'Shopping',
      ),
    ];

    setUp(() {
      // Pre-load items for search tests
      when(
        mockTotpManager.loadTotpItems(),
      ).thenAnswer((_) async => mockTotpItems);
      // Load items first
      totpBloc.add(LoadTotpItems());
    });

    blocTest<TotpBloc, TotpState>(
      'should filter items by search query (service name)',
      build: () => totpBloc,
      seed: () => TotpLoadSuccess(
        totpItems: mockTotpItems,
        filteredTotpItems: mockTotpItems,
      ),
      act: (bloc) => bloc.add(SearchTotpItems('google', null)),
      expect: () => [
        TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: [mockTotpItems[0]],
          searchQuery: 'google',
          categoryFilter: null,
        ),
      ],
    );

    blocTest<TotpBloc, TotpState>(
      'should filter items by search query (username)',
      build: () => totpBloc,
      seed: () => TotpLoadSuccess(
        totpItems: mockTotpItems,
        filteredTotpItems: mockTotpItems,
      ),
      act: (bloc) => bloc.add(SearchTotpItems('user@example', null)),
      expect: () => [
        TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: [mockTotpItems[0]],
          searchQuery: 'user@example',
          categoryFilter: null,
        ),
      ],
    );

    blocTest<TotpBloc, TotpState>(
      'should filter items by category',
      build: () => totpBloc,
      seed: () => TotpLoadSuccess(
        totpItems: mockTotpItems,
        filteredTotpItems: mockTotpItems,
      ),
      act: (bloc) => bloc.add(SearchTotpItems('', 'Work')),
      expect: () => [
        TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: [mockTotpItems[0]],
          searchQuery: '',
          categoryFilter: 'Work',
        ),
      ],
    );

    blocTest<TotpBloc, TotpState>(
      'should filter items by both search query and category',
      build: () => totpBloc,
      seed: () => TotpLoadSuccess(
        totpItems: mockTotpItems,
        filteredTotpItems: mockTotpItems,
      ),
      act: (bloc) => bloc.add(SearchTotpItems('user', 'Development')),
      expect: () => [
        TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: [mockTotpItems[1]],
          searchQuery: 'user',
          categoryFilter: 'Development',
        ),
      ],
    );

    blocTest<TotpBloc, TotpState>(
      'should return all items when search query is empty and no category filter',
      build: () => totpBloc,
      seed: () => TotpLoadSuccess(
        totpItems: mockTotpItems,
        filteredTotpItems: [mockTotpItems[0]], // Previously filtered
      ),
      act: (bloc) => bloc.add(SearchTotpItems('', null)),
      expect: () => [
        TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: mockTotpItems,
          searchQuery: '',
          categoryFilter: null,
        ),
      ],
    );

    blocTest<TotpBloc, TotpState>(
      'should be case insensitive in search',
      build: () => totpBloc,
      seed: () => TotpLoadSuccess(
        totpItems: mockTotpItems,
        filteredTotpItems: mockTotpItems,
      ),
      act: (bloc) => bloc.add(SearchTotpItems('GITHUB', null)),
      expect: () => [
        TotpLoadSuccess(
          totpItems: mockTotpItems,
          filteredTotpItems: [mockTotpItems[1]],
          searchQuery: 'GITHUB',
          categoryFilter: null,
        ),
      ],
    );

    blocTest<TotpBloc, TotpState>(
      'should not emit new state when not in TotpLoadSuccess state',
      build: () => totpBloc,
      seed: () => TotpLoadInProgress(),
      act: (bloc) => bloc.add(SearchTotpItems('test', null)),
      expect: () => [], // No state changes expected
    );
  });

  group('TotpBloc - State Transitions', () {
    test('should handle multiple sequential operations', () async {
      final item1 = TotpItem(
        id: '1',
        serviceName: 'Google',
        username: 'user@example.com',
        secret: 'JBSWY3DPEHPK3PXP',
      );

      final _ = TotpItem(
        id: '2',
        serviceName: 'GitHub',
        username: 'user',
        secret: 'JBSWY3DPEHPK3PXQ',
      );

      when(mockTotpManager.loadTotpItems()).thenAnswer((_) async => []);
      when(mockTotpManager.addTotpItem(any)).thenAnswer((_) async {});
      when(mockTotpManager.loadTotpItems()).thenAnswer((_) async => [item1]);

      // Load initial empty state
      totpBloc.add(LoadTotpItems());
      await Future.delayed(Duration.zero);

      // Add first item
      totpBloc.add(AddTotpItem(item1));
      await Future.delayed(Duration.zero);

      expect(totpBloc.state, isA<TotpLoadSuccess>());
      final successState = totpBloc.state as TotpLoadSuccess;
      expect(successState.totpItems.length, 1);
      expect(successState.totpItems[0].serviceName, 'Google');
    });
  });

  group('TotpBloc - Event Equality', () {
    test('AddTotpItem events with same item should be equal', () {
      final item = TotpItem(
        id: '1',
        serviceName: 'Test',
        username: 'user',
        secret: 'SECRET',
      );

      final event1 = AddTotpItem(item);
      final event2 = AddTotpItem(item);

      expect(event1, equals(event2));
      expect(event1.props, equals(event2.props));
    });

    test('DeleteTotpItem events with same id should be equal', () {
      const event1 = DeleteTotpItem('123');
      const event2 = DeleteTotpItem('123');

      expect(event1, equals(event2));
      expect(event1.props, equals(event2.props));
    });

    test('SearchTotpItems events with same parameters should be equal', () {
      const event1 = SearchTotpItems('query', 'category');
      const event2 = SearchTotpItems('query', 'category');

      expect(event1, equals(event2));
      expect(event1.props, equals(event2.props));
    });
  });

  group('TotpBloc - State Equality', () {
    test('TotpLoadSuccess states with same data should be equal', () {
      final items = [
        TotpItem(
          id: '1',
          serviceName: 'Test',
          username: 'user',
          secret: 'SECRET',
        ),
      ];

      final state1 = TotpLoadSuccess(
        totpItems: items,
        filteredTotpItems: items,
        searchQuery: 'test',
        categoryFilter: 'Work',
      );

      final state2 = TotpLoadSuccess(
        totpItems: items,
        filteredTotpItems: items,
        searchQuery: 'test',
        categoryFilter: 'Work',
      );

      expect(state1, equals(state2));
      expect(state1.props, equals(state2.props));
    });

    test('TotpLoadFailure states with same error should be equal', () {
      const state1 = TotpLoadFailure('Error message');
      const state2 = TotpLoadFailure('Error message');

      expect(state1, equals(state2));
      expect(state1.props, equals(state2.props));
    });
  });
}
