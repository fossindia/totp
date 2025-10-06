import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:totp/src/features/home/presentation/widgets/totp_card.dart';
import 'package:go_router/go_router.dart';
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/di/service_locator.dart';
import 'package:totp/src/core/services/settings_service.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';

class TotpList extends StatefulWidget {
  final ValueNotifier<bool> isEmptyNotifier;
  final String? categoryFilter;
  final TextEditingController searchController;
  final ValueNotifier<String> searchQueryNotifier;

  const TotpList({
    super.key,
    required this.isEmptyNotifier,
    this.categoryFilter,
    required this.searchController,
    required this.searchQueryNotifier,
  });

  @override
  State<TotpList> createState() => _TotpListState();
}

class _TotpListState extends State<TotpList> {
  Timer? _ticker;
  int _totpRefreshInterval = 30; // Default value

  @override
  void initState() {
    super.initState();
    _loadRefreshInterval();
    _startTicker();
    // Dispatch LoadTotpItems event when the widget initializes
    context.read<TotpBloc>().add(LoadTotpItems());
  }

  Future<void> _loadRefreshInterval() async {
    final settingsService = getService<SettingsService>();
    setState(() {
      _totpRefreshInterval = settingsService.getTotpRefreshInterval();
    });
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TotpBloc, TotpState>(
      listener: (context, state) {
        if (state is TotpLoadSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.isEmptyNotifier.value = state.totpItems.isEmpty;
          });
        }
      },
      builder: (context, state) {
        if (state is TotpLoadInProgress) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TotpLoadFailure) {
          return Center(child: Text('Error: ${state.error}'));
        } else if (state is TotpLoadSuccess) {
          // If there are no TOTP items at all, show the empty state message.
          if (state.totpItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No authenticators yet. Tap the + button to add one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.8 * 255).toInt()),
                    ),
                  ),
                ],
              ),
            );
          }

          // Common search bar widget, to avoid repetition
          Widget searchBarWidget = Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 12.0),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TextField(
                controller: widget.searchController,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.search,
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(153),
                    fontSize: 18,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_outlined,
                    color: AppColors.grey,
                    size: 28,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (query) {
                  context.read<TotpBloc>().add(
                    SearchTotpItems(query, widget.categoryFilter),
                  );
                },
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
              ),
            ),
          );

          // Determine if "No matching TOTP items found." message should be shown
          final bool showNoMatchingResultsMessage =
              state.filteredTotpItems.isEmpty && state.searchQuery.isNotEmpty;

          // Calculate total items in the ListView
          int totalListItems = 1; // For search bar
          if (showNoMatchingResultsMessage) {
            totalListItems += 1; // For "No matching items found" message
          } else {
            totalListItems +=
                state.filteredTotpItems.length; // For actual TOTP items
          }
          totalListItems += 1; // For bottom padding

          return ListView.builder(
            itemCount: totalListItems,
            itemBuilder: (context, index) {
              if (index == 0) {
                return searchBarWidget;
              } else if (index == totalListItems - 1) {
                return const SizedBox(height: 80.0); // Bottom padding
              } else {
                // Content area (either message or TOTP cards)
                if (showNoMatchingResultsMessage) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No matching TOTP items found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(180),
                        ),
                      ),
                    ),
                  );
                } else {
                  // Display TOTP cards
                  final item =
                      state.filteredTotpItems[index -
                          1]; // Adjust index for search bar
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TotpCard(
                      totpItem: item,
                      interval: _totpRefreshInterval,
                      onEdit: () async {
                        final bool? edited = await context.push<bool>(
                          '/edit_account',
                          extra: item,
                        );
                        if (edited == true) {
                          if (!mounted) return;
                          context.read<TotpBloc>().add(LoadTotpItems());
                        }
                      },
                    ),
                  );
                }
              }
            },
          );
        }
        return const SizedBox.shrink(); // Default empty widget
      },
    );
  }
}
