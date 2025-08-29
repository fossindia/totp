import 'package:equatable/equatable.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

abstract class TotpEvent extends Equatable {
  const TotpEvent();

  @override
  List<Object> get props => [];
}

class LoadTotpItems extends TotpEvent {}

class AddTotpItem extends TotpEvent {
  final TotpItem totpItem;

  const AddTotpItem(this.totpItem);

  @override
  List<Object> get props => [totpItem];
}

class UpdateTotpItem extends TotpEvent {
  final TotpItem totpItem;

  const UpdateTotpItem(this.totpItem);

  @override
  List<Object> get props => [totpItem];
}

class DeleteTotpItem extends TotpEvent {
  final String id;

  const DeleteTotpItem(this.id);

  @override
  List<Object> get props => [id];
}

class SearchTotpItems extends TotpEvent {
  final String query;
  final String? categoryFilter;

  const SearchTotpItems(this.query, this.categoryFilter);

  @override
  List<Object> get props => [query, categoryFilter ?? ''];
}
