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

  QrCodeProcessResult({required this.type, this.totpItem, this.errorMessage});
}

class QrCodeProcessorService {
  final TotpManager _totpManager;

  QrCodeProcessorService({TotpManager? totpManager})
    : _totpManager = totpManager ?? TotpManager();

  Future<QrCodeProcessResult> processQrCode(String qrData) async {
    // Input validation and sanitization
    if (!_isValidInput(qrData)) {
      return QrCodeProcessResult(
        type: QrCodeProcessResultType.invalidFormat,
        errorMessage: 'Invalid QR code format.',
      );
    }

    try {
      final Uri uri = Uri.parse(qrData);

      // Validate TOTP format more strictly
      if (!_isValidTotpUri(uri)) {
        return QrCodeProcessResult(
          type: QrCodeProcessResultType.invalidFormat,
          errorMessage: 'Invalid TOTP QR code format.',
        );
      }

      final String? secret = uri.queryParameters['secret']?.trim();
      final String? issuer = uri.queryParameters['issuer']?.trim();
      final String label = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last.trim()
          : 'Unknown';

      // Validate and sanitize secret
      if (!_isValidSecret(secret)) {
        return QrCodeProcessResult(
          type: QrCodeProcessResultType.noSecret,
          errorMessage: 'QR code contains invalid secret.',
        );
      }

      final String username = label.contains(':')
          ? label.split(':').last
          : label;
      final TotpItem newItem = TotpItem(
        id: '',
        serviceName: _sanitizeInput(issuer ?? label),
        username: _sanitizeInput(username),
        secret: secret!,
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
    } catch (e) {
      debugPrint('Error parsing QR code');
      return QrCodeProcessResult(
        type: QrCodeProcessResultType.error,
        errorMessage: 'Error parsing QR code.',
      );
    }
  }

  // Input validation methods
  bool _isValidInput(String input) {
    if (input.isEmpty || input.length > 2000) return false;

    // Check for potentially dangerous characters
    // Use a raw triple-quoted string so we can include both single and double quotes
    // and a backslash in the character class safely.
    final dangerousChars = RegExp(r'''[<>'"\\]''');
    return !dangerousChars.hasMatch(input);
  }

  bool _isValidTotpUri(Uri uri) {
    return uri.scheme == 'otpauth' &&
        uri.host == 'totp' &&
        uri.pathSegments.isNotEmpty;
  }

  bool _isValidSecret(String? secret) {
    if (secret == null || secret.isEmpty) return false;

    // Base32 validation - TOTP secrets should be base32 encoded
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    return base32Regex.hasMatch(secret.toUpperCase()) && secret.length <= 1000;
  }

  String _sanitizeInput(String input) {
    // Remove potentially dangerous characters and limit length
    // Keep the same character set as the validator: <, >, single-quote, double-quote and backslash.
    final sanitized = input.replaceAll(RegExp(r'''[<>'"\\]'''), '');
    return sanitized.substring(
      0,
      sanitized.length > 100 ? 100 : sanitized.length,
    );
  }

  Future<void> addTotpItem(TotpItem item) async {
    await _totpManager.addTotpItem(item);
  }
}
