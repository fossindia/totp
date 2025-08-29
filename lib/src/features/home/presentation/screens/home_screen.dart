import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:totp/src/features/home/presentation/widgets/totp_list.dart';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final ValueNotifier<bool> _isTotpListEmpty = ValueNotifier<bool>(true);

  String? _selectedCategory;
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<TotpBloc>().add(
        SearchTotpItems(_searchController.text, _selectedCategory),
      );
    });
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final TotpManager totpManager = TotpManager();
    final List<TotpItem> items = await totpManager.loadTotpItems();
    final Set<String> uniqueCategories = items
        .where((item) => item.category != null && item.category!.isNotEmpty)
        .map((item) => item.category!)
        .toSet();
    setState(() {
      _categories = ['All', ...uniqueCategories.toList()..sort()];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _isTotpListEmpty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
        systemNavigationBarIconBrightness:
            Theme.of(context).colorScheme.surface.computeLuminance() > 0.5
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        title: Text(
          AppStrings.totpAuthenticator,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            position: PopupMenuPosition.under,
            icon: Icon(
              Icons.filter_alt_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: 28,
            ),
            onSelected: (String newValue) {
              setState(() {
                _selectedCategory = newValue == 'All' ? null : newValue;
                context.read<TotpBloc>().add(
                  SearchTotpItems(_searchController.text, _selectedCategory),
                );
              });
            },
            itemBuilder: (BuildContext context) {
              return _categories.map((String category) {
                return PopupMenuItem<String>(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),

                  value: category,
                  child: Text(category),
                );
              }).toList();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.onSurface,
              size: 28,
            ),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: TotpList(
          isEmptyNotifier: _isTotpListEmpty,
          categoryFilter: _selectedCategory,
          searchController: _searchController,
          searchQueryNotifier: _searchQuery,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/qr_scanner');
          if (result == true) {
            if (!mounted) return;
            context.read<TotpBloc>().add(LoadTotpItems());
          }
        },
        backgroundColor: AppColors.primaryPurple,
        elevation: 5,
        child: const Icon(Icons.add_outlined, color: AppColors.white, size: 32),
      ),
    );
  }
}
