import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/core/di/service_locator.dart';
import 'package:totp/src/features/totp_generation/totp_service.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';
import 'package:totp/src/blocs/totp_bloc/totp_state.dart';

class TotpCard extends StatefulWidget {
  final TotpItem totpItem;
  final VoidCallback? onEdit;
  final int interval;

  const TotpCard({
    super.key,
    required this.totpItem,
    this.onEdit,
    this.interval = 30,
  });

  @override
  State<TotpCard> createState() => _TotpCardState();
}

class _TotpCardState extends State<TotpCard> {
  bool _copyTotpOnTap = true;

  @override
  void initState() {
    super.initState();
    _loadCopyTotpOnTapSetting();
  }

  Future<void> _loadCopyTotpOnTapSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _copyTotpOnTap = prefs.getBool('copyTotpOnTap') ?? true;
    });
  }

  void _copyOtpToClipboard(String otp) {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: otp.replaceAll(' ', '')));
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.copiedCode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final totpService = getService<TotpService>();

    return BlocSelector<TotpBloc, TotpState, String>(
      selector: (state) {
        if (state is TotpLoadSuccess) {
          try {
            final item = state.totpItems.firstWhere(
              (item) => item.id == widget.totpItem.id,
            );
            return totpService.generateTotp(
              item.secret,
              interval: widget.interval,
            );
          } catch (e) {
            return '000000';
          }
        }
        return '000000';
      },
      builder: (context, otp) {
        return GestureDetector(
          onTap: _copyTotpOnTap ? () => _copyOtpToClipboard(otp) : null,
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 24,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.totpItem.serviceName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.totpItem.username,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (widget.totpItem.category != null &&
                                widget.totpItem.category!.isNotEmpty)
                              Text(
                                widget.totpItem.category!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Use BlocSelector for efficient timer updates
                      BlocSelector<TotpBloc, TotpState, int>(
                        selector: (state) {
                          if (state is TotpLoadSuccess) {
                            try {
                              state.totpItems.firstWhere(
                                (item) => item.id == widget.totpItem.id,
                              );
                              return totpService.getRemainingSeconds(
                                interval: widget.interval,
                              );
                            } catch (e) {
                              return widget.interval;
                            }
                          }
                          return widget.interval;
                        },
                        builder: (context, remainingSeconds) {
                          return SizedBox(
                            width: 40,
                            height: 40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: remainingSeconds / widget.interval,
                                  strokeWidth: 3,
                                  backgroundColor: colorScheme.surface,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  remainingSeconds.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Use BlocSelector for efficient TOTP code updates
                      BlocSelector<TotpBloc, TotpState, String>(
                        selector: (state) {
                          if (state is TotpLoadSuccess) {
                            try {
                              final item = state.totpItems.firstWhere(
                                (item) => item.id == widget.totpItem.id,
                              );
                              return totpService.generateTotp(
                                item.secret,
                                interval: widget.interval,
                              );
                            } catch (e) {
                              return '000000';
                            }
                          }
                          return '000000';
                        },
                        builder: (context, otp) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Text(
                              otp,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
                      if (!_copyTotpOnTap)
                        BlocSelector<TotpBloc, TotpState, String>(
                          selector: (state) {
                            if (state is TotpLoadSuccess) {
                              try {
                                final item = state.totpItems.firstWhere(
                                  (item) => item.id == widget.totpItem.id,
                                );
                                return totpService.generateTotp(
                                  item.secret,
                                  interval: widget.interval,
                                );
                              } catch (e) {
                                return '000000';
                              }
                            }
                            return '000000';
                          },
                          builder: (context, otp) {
                            return IconButton(
                              icon: const Icon(Icons.copy_outlined),
                              onPressed: () => _copyOtpToClipboard(otp),
                              tooltip: 'Copy OTP',
                            );
                          },
                        ),

                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: widget.onEdit,
                        tooltip: 'Edit Account',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
