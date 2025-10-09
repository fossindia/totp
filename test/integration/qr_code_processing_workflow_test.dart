import 'package:flutter_test/flutter_test.dart';
import 'package:totp/src/core/services/qr_code_processor_service.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';

// Simple mock implementation
class MockTotpManager implements TotpManager {
  final List<TotpItem> _items = [];

  @override
  Future<List<TotpItem>> loadTotpItems() async => _items;

  @override
  Future<void> saveTotpItems(List<TotpItem> items) async {
    _items.clear();
    _items.addAll(items);
  }

  @override
  Future<void> addTotpItem(TotpItem newItem) async {
    final itemWithId = TotpItem(
      id: 'mock-id-${_items.length}',
      serviceName: newItem.serviceName,
      username: newItem.username,
      secret: newItem.secret,
      category: newItem.category,
    );
    _items.add(itemWithId);
  }

  @override
  Future<void> updateTotpItem(TotpItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
    }
  }

  @override
  Future<void> deleteTotpItem(String id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<bool> doesTotpItemExist(TotpItem newItem) async {
    return _items.any(
      (item) =>
          item.serviceName == newItem.serviceName &&
          item.username == newItem.username &&
          item.secret == newItem.secret,
    );
  }
}

void main() {
  late QrCodeProcessorService qrProcessor;
  late MockTotpManager mockTotpManager;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockTotpManager = MockTotpManager();
    qrProcessor = QrCodeProcessorService(totpManager: mockTotpManager);
  });

  group('QR Code Processing Workflow Integration Tests', () {
    group('Valid QR Code Processing Flow', () {
      test('should successfully process valid QR code', () async {
        const qrCode = 'otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP';

        final result = await qrProcessor.processQrCode(qrCode);

        expect(result.type, QrCodeProcessResultType.success);
        expect(result.totpItem, isNotNull);
        expect(result.errorMessage, isNull);
        expect(result.totpItem!.serviceName, 'Test:user');
        expect(result.totpItem!.username, 'user');
        expect(result.totpItem!.secret, 'JBSWY3DPEHPK3PXP');
        expect(result.totpItem!.id, isEmpty);
      });

      test('should handle QR code with issuer parameter', () async {
        const qrCode =
            'otpauth://totp/Google:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Google';

        final result = await qrProcessor.processQrCode(qrCode);

        expect(result.type, QrCodeProcessResultType.success);
        expect(result.totpItem!.serviceName, 'Google');
        expect(result.totpItem!.username, 'user@example.com');
      });

      test('should handle QR code with colon in label', () async {
        const qrCode =
            'otpauth://totp/Company:user@domain.com?secret=JBSWY3DPEHPK3PXR&issuer=Company';

        final result = await qrProcessor.processQrCode(qrCode);

        expect(result.type, QrCodeProcessResultType.success);
        expect(result.totpItem!.serviceName, 'Company');
        expect(result.totpItem!.username, 'user@domain.com');
      });

      test('should add processed account to storage', () async {
        const qrCode = 'otpauth://totp/Test:user?secret=JBSWY3DPEHPK3PXP';

        final result = await qrProcessor.processQrCode(qrCode);
        expect(result.type, QrCodeProcessResultType.success);

        await qrProcessor.addTotpItem(result.totpItem!);

        final storedItems = await mockTotpManager.loadTotpItems();
        expect(storedItems.length, 1);
        expect(storedItems[0].serviceName, 'Test:user');
      });
    });

    group('Duplicate Detection Flow', () {
      test('should detect duplicate accounts', () async {
        const qrCode =
            'otpauth://totp/Google:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Google';
        final existingItem = TotpItem(
          id: 'existing-id',
          serviceName: 'Google',
          username: 'user@example.com',
          secret: 'JBSWY3DPEHPK3PXP',
        );
        await mockTotpManager.addTotpItem(existingItem);

        final result = await qrProcessor.processQrCode(qrCode);

        expect(result.type, QrCodeProcessResultType.duplicate);
        expect(result.totpItem, isNotNull);
        expect(result.totpItem!.serviceName, 'Google');
        expect(result.errorMessage, isNull);
      });

      test('should allow processing when no duplicate exists', () async {
        const qrCode = 'otpauth://totp/NewService:user?secret=JBSWY3DPEHPK3PXQ';

        final result = await qrProcessor.processQrCode(qrCode);

        expect(result.type, QrCodeProcessResultType.success);
        expect(result.totpItem!.serviceName, 'NewService:user');
      });
    });

    group('Invalid QR Code Handling', () {
      test('should reject invalid QR code formats', () async {
        const invalidQrs = [
          'not-a-qr-code',
          'otpauth://hotp/Google:user@example.com?secret=JBSWY3DPEHPK3PXP',
          'https://example.com/totp?secret=JBSWY3DPEHPK3PXP',
          'otpauth://totp/?secret=JBSWY3DPEHPK3PXP',
          'otpauth://totp/Google:user@example.com',
          'otpauth://totp/Google:user@example.com?secret=INVALID_SECRET',
        ];

        for (final invalidQr in invalidQrs) {
          final result = await qrProcessor.processQrCode(invalidQr);
          expect(
            result.type,
            anyOf(
              QrCodeProcessResultType.invalidFormat,
              QrCodeProcessResultType.noSecret,
              QrCodeProcessResultType.error,
            ),
          );
          expect(result.errorMessage, isNotNull);
          expect(result.totpItem, isNull);
        }
      });

      test('should sanitize dangerous input characters', () async {
        const dangerousQr =
            'otpauth://totp/<script>alert("xss")</script>:user?secret=JBSWY3DPEHPK3PXP&issuer=<dangerous>';

        final result = await qrProcessor.processQrCode(dangerousQr);

        expect(result.type, QrCodeProcessResultType.invalidFormat);
        expect(result.errorMessage, contains('Invalid QR code format'));
      });
    });

    group('Workflow Integration', () {
      test('should complete full workflow from QR to storage', () async {
        const qrCode =
            'otpauth://totp/MyBank:user@mybank.com?secret=JBSWY3DPEHPK3PXP&issuer=MyBank';

        final processResult = await qrProcessor.processQrCode(qrCode);
        expect(processResult.type, QrCodeProcessResultType.success);

        final itemToAdd = processResult.totpItem!;
        await qrProcessor.addTotpItem(itemToAdd);

        final storedItems = await mockTotpManager.loadTotpItems();
        expect(storedItems.length, 1);
        expect(storedItems[0].serviceName, 'MyBank');
        expect(storedItems[0].username, 'user@mybank.com');
        expect(storedItems[0].secret, 'JBSWY3DPEHPK3PXP');
        expect(storedItems[0].id, isNotEmpty);
      });
    });
  });
}
