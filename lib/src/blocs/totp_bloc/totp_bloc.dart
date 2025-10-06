import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';
import 'package:totp/src/core/errors/error_handler.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

/// BLoC for managing TOTP items state and operations.
///
/// Handles loading, adding, updating, deleting, and searching TOTP items.
/// Uses [TotpManager] for data persistence.
class TotpBloc extends Bloc<TotpEvent, TotpState> {
  final TotpManager _totpManager;
  List<TotpItem> _allTotpItems = [];

  TotpBloc(this._totpManager) : super(TotpInitial()) {
    on<LoadTotpItems>(_onLoadTotpItems);
    on<AddTotpItem>(_onAddTotpItem);
    on<UpdateTotpItem>(_onUpdateTotpItem);
    on<DeleteTotpItem>(_onDeleteTotpItem);
    on<SearchTotpItems>(_onSearchTotpItems);
  }

  /// Loads TOTP items from storage and emits success or failure state.
  Future<void> _onLoadTotpItems(
    LoadTotpItems event,
    Emitter<TotpState> emit,
  ) async {
    emit(TotpLoadInProgress());
    try {
      _allTotpItems = await _totpManager.loadTotpItems();
      emit(
        TotpLoadSuccess(
          totpItems: _allTotpItems,
          filteredTotpItems: _allTotpItems,
        ),
      );
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      emit(TotpLoadFailure('Failed to load TOTP items'));
    }
  }

  /// Adds a new TOTP item and reloads the list.
  Future<void> _onAddTotpItem(
    AddTotpItem event,
    Emitter<TotpState> emit,
  ) async {
    try {
      await _totpManager.addTotpItem(event.totpItem);
      add(LoadTotpItems()); // Reload items after adding
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      emit(TotpLoadFailure('Failed to add TOTP item'));
    }
  }

  Future<void> _onUpdateTotpItem(
    UpdateTotpItem event,
    Emitter<TotpState> emit,
  ) async {
    try {
      await _totpManager.updateTotpItem(event.totpItem);
      add(LoadTotpItems()); // Reload items after updating
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      emit(TotpLoadFailure('Failed to update TOTP item'));
    }
  }

  Future<void> _onDeleteTotpItem(
    DeleteTotpItem event,
    Emitter<TotpState> emit,
  ) async {
    try {
      await _totpManager.deleteTotpItem(event.id);
      add(LoadTotpItems()); // Reload items after deleting
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      emit(TotpLoadFailure('Failed to delete TOTP item'));
    }
  }

  /// Filters TOTP items based on search query and category.
  void _onSearchTotpItems(SearchTotpItems event, Emitter<TotpState> emit) {
    if (state is TotpLoadSuccess) {
      final currentState = state as TotpLoadSuccess;
      final filteredItems = _allTotpItems.where((item) {
        final queryLower = event.query.toLowerCase();
        final matchesSearch =
            item.serviceName.toLowerCase().contains(queryLower) ||
            item.username.toLowerCase().contains(queryLower);

        final matchesCategory =
            event.categoryFilter == null ||
            item.category == event.categoryFilter;

        return matchesSearch && matchesCategory;
      }).toList();
      emit(
        currentState.copyWith(
          filteredTotpItems: filteredItems,
          searchQuery: event.query,
          categoryFilter: event.categoryFilter,
        ),
      );
    }
  }
}
