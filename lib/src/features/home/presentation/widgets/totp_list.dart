import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:totp/src/features/home/presentation/widgets/totp_card.dart';
import 'package:go_router/go_router.dart';
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/di/service_locator.dart';
import 'package:totp/src/core/services/settings_service.dart';
import 'package:totp/src/core/services/performance_monitor_service.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';
import 'package:totp/src/features/totp_generation/totp_service.dart';

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
  final ScrollController _scrollController = ScrollController();

  // Virtualization state
  final Set<String> _visibleItems =
      {}; // Track visible item IDs for lazy loading
  final Map<String, Widget> _widgetCache = {}; // Cache rendered widgets
  final Map<String, DateTime> _lastAccessTime =
      {}; // Track access times for cache cleanup
  static const int _maxCacheSize = 50; // Maximum cached widgets
  static const Duration _cacheExpiry = Duration(
    minutes: 5,
  ); // Cache expiry time

  // Widget caching for performance optimization

  @override
  void initState() {
    super.initState();
    _loadRefreshInterval();
    _startTicker();
    _setupScrollController();
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

  void _setupScrollController() {
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrollStartTime = DateTime.now();

    // Implement lazy loading when scrolling near the end
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreItemsIfNeeded();
    }

    // Track scroll performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollEndTime = DateTime.now();
      final scrollDuration = scrollEndTime.difference(scrollStartTime);

      PerformanceMonitor.recordScrollPerformance(
        scrollDistance: _scrollController.position.pixels,
        scrollTime: scrollDuration,
        itemCount: _visibleItems.length,
      );
    });
  }

  void _loadMoreItemsIfNeeded() {
    // For now, show all items initially. This can be enhanced later for true pagination
    // when the list becomes very large (1000+ items)
  }

  /// Get paginated items for current page (initially returns all items)
  List<dynamic> _getPaginatedItems(TotpLoadSuccess state) {
    // For now, return all filtered items to maintain compatibility
    // This can be enhanced to true pagination when needed
    return state.filteredTotpItems;
  }

  /// Get cached widget or create new one
  Widget _getCachedWidget(String itemId, Widget Function() widgetBuilder) {
    // Clean expired cache entries
    _cleanupExpiredCache();

    // Check if widget is cached and not expired
    if (_widgetCache.containsKey(itemId)) {
      _lastAccessTime[itemId] = DateTime.now();
      return _widgetCache[itemId]!;
    }

    // Create new widget and cache it
    final widget = widgetBuilder();
    _cacheWidget(itemId, widget);
    return widget;
  }

  /// Cache a widget
  void _cacheWidget(String itemId, Widget widget) {
    // Remove oldest entries if cache is full
    if (_widgetCache.length >= _maxCacheSize) {
      _evictOldestCacheEntries();
    }

    _widgetCache[itemId] = widget;
    _lastAccessTime[itemId] = DateTime.now();
  }

  /// Clean up expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _lastAccessTime.forEach((key, accessTime) {
      if (now.difference(accessTime) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _widgetCache.remove(key);
      _lastAccessTime.remove(key);
    }
  }

  /// Evict oldest cache entries when cache is full
  void _evictOldestCacheEntries() {
    if (_lastAccessTime.isEmpty) return;

    // Sort by access time (oldest first)
    final sortedEntries = _lastAccessTime.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Remove oldest 25% of entries
    final entriesToRemove = (sortedEntries.length * 0.25).ceil();
    final keysToRemove = sortedEntries.take(entriesToRemove).map((e) => e.key);

    for (final key in keysToRemove) {
      _widgetCache.remove(key);
      _lastAccessTime.remove(key);
    }
  }

  /// Clear all caches (useful when data changes)
  void _clearCaches() {
    _widgetCache.clear();
    _lastAccessTime.clear();
    _visibleItems.clear();
  }

  /// Reset caches when data changes
  void _resetCaches() {
    _clearCaches(); // Clear caches when data changes
  }

  /// Preload TOTP codes for visible items to improve performance
  void _preloadVisibleItems(List<String> visibleItemIds) {
    final preloadTimer = PerformanceTimer('TOTP List Preload', {
      'visible_items': visibleItemIds.length,
    });

    try {
      final totpService = getService<TotpService>();
      final newVisibleItems = visibleItemIds.toSet().difference(_visibleItems);

      if (newVisibleItems.isNotEmpty) {
        // Preload TOTP codes asynchronously for better performance
        final secrets = newVisibleItems.toList();
        totpService
            .preloadTotpCodesAsync(secrets, interval: _totpRefreshInterval)
            .then((_) {
              // Update visible items after successful preloading
              _visibleItems.addAll(newVisibleItems);
              preloadTimer.finish(
                additionalMetadata: {
                  'result': 'async_success',
                  'preloaded_count': secrets.length,
                },
              );
            })
            .catchError((error) {
              // Fallback to synchronous preloading if async fails
              totpService.preloadTotpCodes(
                secrets,
                interval: _totpRefreshInterval,
              );
              _visibleItems.addAll(newVisibleItems);
              preloadTimer.finish(
                additionalMetadata: {
                  'result': 'sync_fallback',
                  'preloaded_count': secrets.length,
                  'error': error.toString(),
                },
              );
            });
      } else {
        preloadTimer.finish(additionalMetadata: {'result': 'no_new_items'});
      }

      // Clean up items that are no longer visible
      final noLongerVisible = _visibleItems.difference(visibleItemIds.toSet());
      _visibleItems.removeAll(noLongerVisible);
    } catch (e) {
      preloadTimer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
    }
  }

  /// Update visible items for lazy loading
  void _updateVisibleItems() {
    // Calculate which items are currently visible
    final viewportDimension = _scrollController.position.viewportDimension;
    final offset = _scrollController.offset;

    // Estimate visible item indices (rough calculation)
    final itemHeight = 120.0; // Approximate height of each item
    final firstVisibleIndex = (offset / itemHeight).floor();
    final visibleCount =
        (viewportDimension / itemHeight).ceil() + 2; // Add buffer
    final lastVisibleIndex = firstVisibleIndex + visibleCount;

    // Get visible item IDs from current state
    final blocState = context.read<TotpBloc>().state;
    if (blocState is TotpLoadSuccess) {
      final visibleItems = blocState.filteredTotpItems
          .skip(firstVisibleIndex.clamp(0, blocState.filteredTotpItems.length))
          .take(
            (lastVisibleIndex - firstVisibleIndex).clamp(
              0,
              blocState.filteredTotpItems.length,
            ),
          )
          .map((item) => item.secret)
          .toList();

      _preloadVisibleItems(visibleItems);
    }
  }

  /// Build virtualized TOTP card with performance optimizations
  Widget _buildVirtualizedTotpCard(dynamic item) {
    return _getCachedWidget(
      item.id,
      () => RepaintBoundary(
        // Isolate repaints for better performance
        child: TotpCard(
          key: ValueKey(item.id), // Stable key for efficient recycling
          totpItem: item,
          interval: _totpRefreshInterval,
          onEdit: () async {
            final bool? edited = await context.push<bool>(
              '/edit_account',
              extra: item,
            );
            if (edited == true) {
              if (!mounted) return;
              // Clear cache when item is edited
              _clearCaches();
              context.read<TotpBloc>().add(LoadTotpItems());
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scrollController.dispose();
    _clearCaches(); // Clean up all caches
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renderTimer = PerformanceTimer('TotpList Build');

    try {
      return BlocConsumer<TotpBloc, TotpState>(
        listener: (context, state) {
          if (state is TotpLoadSuccess) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.isEmptyNotifier.value = state.totpItems.isEmpty;
              // Reset caches when data changes
              _resetCaches();
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

            // Get paginated items for virtualization
            final paginatedItems = _getPaginatedItems(state);

            // Determine if "No matching TOTP items found." message should be shown
            final bool showNoMatchingResultsMessage =
                state.filteredTotpItems.isEmpty && state.searchQuery.isNotEmpty;

            // Calculate total items in the ListView
            int totalListItems = 1; // For search bar
            if (showNoMatchingResultsMessage) {
              totalListItems += 1; // For "No matching items found" message
            } else {
              totalListItems += paginatedItems.length; // For TOTP items
            }
            totalListItems += 1; // For bottom padding

            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                // Track visible items for lazy loading
                if (scrollInfo is ScrollUpdateNotification) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateVisibleItems();
                  });
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: totalListItems,
                // Add automatic keep alive for better performance
                addAutomaticKeepAlives: true,
                // Add semantic indexes for accessibility
                addSemanticIndexes: true,
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
                      // Display TOTP cards with virtualization
                      final itemIndex =
                          index - 1; // Adjust index for search bar
                      if (itemIndex < paginatedItems.length) {
                        final item = paginatedItems[itemIndex];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildVirtualizedTotpCard(item),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  }
                },
              ),
            );
          }
          return const SizedBox.shrink(); // Default empty widget
        },
      );
    } catch (e) {
      renderTimer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    } finally {
      renderTimer.finish(additionalMetadata: {'result': 'success'});
    }
  }
}
