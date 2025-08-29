import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/constants/strings.dart';

class TotpCard extends StatefulWidget {
  final TotpItem totpItem;
  final String otp;
  final int remainingSeconds;
  final VoidCallback? onEdit;
  final int interval;

  const TotpCard({
    super.key,
    required this.totpItem,
    required this.otp,
    required this.remainingSeconds,
    this.onEdit,
    required this.interval,
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

  void _copyOtpToClipboard() {
    final messenger = ScaffoldMessenger.of(context);
    Clipboard.setData(ClipboardData(text: widget.otp.replaceAll(' ', '')));
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.copiedCode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _copyTotpOnTap ? _copyOtpToClipboard : null,
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
                      color: AppColors
                          .white, // Mimicking the GitHub icon background
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
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: widget.remainingSeconds / widget.interval,
                          strokeWidth: 3,
                          backgroundColor: colorScheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                        Text(
                          widget.remainingSeconds.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      widget.otp,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (!_copyTotpOnTap)
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: _copyOtpToClipboard,
                      tooltip: 'Copy OTP',
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
  }
}
