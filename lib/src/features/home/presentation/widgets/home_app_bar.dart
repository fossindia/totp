import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';
import 'package:totp/src/core/constants/strings.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final TextEditingController searchController;

  const HomeAppBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
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
            onCategorySelected(newValue == 'All' ? null : newValue);
            context.read<TotpBloc>().add(
                  SearchTotpItems(searchController.text, newValue == 'All' ? null : newValue),
                );
          },
          itemBuilder: (BuildContext context) {
            return categories.map((String category) {
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
