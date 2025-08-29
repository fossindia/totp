import 'package:equatable/equatable.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

abstract class TotpState extends Equatable {
  const TotpState();

  @override
  List<Object> get props => [];
}

class TotpInitial extends TotpState {}

class TotpLoadInProgress extends TotpState {}

class TotpLoadSuccess extends TotpState {
  final List<TotpItem> totpItems;
  final List<TotpItem> filteredTotpItems;
  final String searchQuery;
  final String? categoryFilter;

  const TotpLoadSuccess({
    this.totpItems = const [],
    this.filteredTotpItems = const [],
    this.searchQuery = '',
    this.categoryFilter,
  });

  TotpLoadSuccess copyWith({
    List<TotpItem>? totpItems,
    List<TotpItem>? filteredTotpItems,
    String? searchQuery,
    String? categoryFilter,
  }) {
    return TotpLoadSuccess(
      totpItems: totpItems ?? this.totpItems,
      filteredTotpItems: filteredTotpItems ?? this.filteredTotpItems,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
    );
  }

  @override
  List<Object> get props => [
    totpItems,
    filteredTotpItems,
    searchQuery,
    categoryFilter ?? '',
  ];
}

class TotpLoadFailure extends TotpState {
  final String error;

  const TotpLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}
