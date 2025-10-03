import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';

class DataManagementService {
  final TotpManager _totpManager;

  DataManagementService({TotpManager? totpManager})
    : _totpManager = totpManager ?? TotpManager();

  Future<List<TotpItem>> loadTotpItemsForCheck() async {
    return await _totpManager.loadTotpItems();
  }

  Future<void> exportAccounts() async {
    final List<TotpItem> items = await _totpManager.loadTotpItems();
    final String jsonString = json.encode(
      items.map((item) => item.toJson()).toList(),
    );
    final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

    await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'totp_accounts.json',
      bytes: jsonBytes,
    );
  }

  Future<int> importAccounts() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();

      final List<dynamic> jsonList = json.decode(jsonString);
      final List<TotpItem> importedItems = jsonList
          .map((json) => TotpItem.fromJson(json))
          .toList();

      int newItemsCount = 0;
      for (final item in importedItems) {
        final bool itemExists = await _totpManager.doesTotpItemExist(item);
        if (!itemExists) {
          await _totpManager.addTotpItem(item);
          newItemsCount++;
        }
      }
      return newItemsCount;
    }
    return 0;
  }
}
