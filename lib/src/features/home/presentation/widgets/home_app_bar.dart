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
        // Use an explicit IconButton + showMenu to avoid a framework bug where
        // PopupMenuButton's internal ancestor lookup can run against a
        // deactivated context (causing "Looking up a deactivated widget's ancestor is unsafe").
        Builder(
          builder: (builderContext) {
            return IconButton(
              icon: Icon(
                Icons.filter_alt_outlined,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
              onPressed: () async {
                // Compute the button's rect & overlay size to position the menu.
                final RenderBox button =
                    builderContext.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(builderContext).context.findRenderObject()
                        as RenderBox;
                final RelativeRect position = RelativeRect.fromRect(
                  button.localToGlobal(Offset.zero) & button.size,
                  Offset.zero & overlay.size,
                );

                final String? selected = await showMenu<String>(
                  context: builderContext,
                  position: position,
                  items: categories.map((String category) {
                    return PopupMenuItem<String>(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                );

                if (selected != null) {
                  onCategorySelected(selected == 'All' ? null : selected);
                  builderContext.read<TotpBloc>().add(
                    SearchTotpItems(
                      searchController.text,
                      selected == 'All' ? null : selected,
                    ),
                  );
                }
              },
            );
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
