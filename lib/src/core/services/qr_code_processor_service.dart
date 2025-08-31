import 'package:flutter/material.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';

enum QrCodeProcessResultType {
  success,
  invalidFormat,
  noSecret,
  duplicate,
  error,
}

class QrCodeProcessResult {
  final QrCodeProcessResultType type;
  final TotpItem? totpItem;
  final String? errorMessage;

  QrCodeProcessResult({
    required this.type,
    this.totpItem,
    this.errorMessage,
  });
}

class QrCodeProcessorService {
  final TotpManager _totpManager;

  QrCodeProcessorService({TotpManager? totpManager})
      : _totpManager = totpManager ?? TotpManager();

  Future<QrCodeProcessResult> processQrCode(String qrData) async {
    try {
      final Uri uri = Uri.parse(qrData);

      if (uri.scheme == 'otpauth' && uri.host == 'totp') {
        final String? secret = uri.queryParameters['secret']?.trim();
        final String? issuer = uri.queryParameters['issuer'];
        final String label = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'Unknown';

        if (secret == null || secret.isEmpty) {
          return QrCodeProcessResult(
            type: QrCodeProcessResultType.noSecret,
            errorMessage: 'QR Code does not contain a secret.',
          );
        }

        final String username = label.contains(':')
            ? label.split(':').last
            : label;
        final TotpItem newItem = TotpItem(
          id: '',
          serviceName: issuer ?? label,
          username: username,
          secret: secret,
        );

        bool isDuplicate = await _totpManager.doesTotpItemExist(newItem);

        if (isDuplicate) {
          return QrCodeProcessResult(
            type: QrCodeProcessResultType.duplicate,
            totpItem: newItem,
          );
        }

        return QrCodeProcessResult(
          type: QrCodeProcessResultType.success,
          totpItem: newItem,
        );
      } else {
        return QrCodeProcessResult(
          type: QrCodeProcessResultType.invalidFormat,
          errorMessage: 'Invalid TOTP QR Code format.',
        );
      }
    } catch (e) {
      debugPrint('Error parsing QR code: $e');
      return QrCodeProcessResult(
        type: QrCodeProcessResultType.error,
        errorMessage: 'Error parsing QR Code: $e',
      );
    }
  }

  Future<void> addTotpItem(TotpItem item) async {
    await _totpManager.addTotpItem(item);
  }
}
