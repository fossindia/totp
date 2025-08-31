import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_event.dart';
import 'package:totp/src/core/constants/colors.dart';

class HomeFloatingActionButton extends StatelessWidget {
  const HomeFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final result = await context.push<bool>('/qr_scanner');
        if (result == true) {
          if (!context.mounted) return;
          context.read<TotpBloc>().add(LoadTotpItems());
        }
      },
      backgroundColor: AppColors.primaryPurple,
      elevation: 5,
      child: const Icon(Icons.add_outlined, color: AppColors.white, size: 32),
    );
  }
}
