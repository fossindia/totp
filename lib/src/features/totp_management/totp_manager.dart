import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/core/utils/encryption_util.dart';
import 'dart:convert';

class TotpManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();
  static const String _storageKey = 'totp_items';

  Future<List<TotpItem>> loadTotpItems() async {
    final String? encryptedTotpItems = await _secureStorage.read(
      key: _storageKey,
    );
    if (encryptedTotpItems == null) {
      return [];
    }
    final String decryptedTotpItems = EncryptionUtil.decrypt(
      encryptedTotpItems,
    );
    final List<dynamic> jsonList = json.decode(decryptedTotpItems);
    // log('Loaded TOTP items: ${json.encode(jsonList)}'); // Log after decryption
    return jsonList.map((json) => TotpItem.fromJson(json)).toList();
  }

  Future<void> saveTotpItems(List<TotpItem> items) async {
    final List<Map<String, dynamic>> jsonList = items
        .map((item) => item.toJson())
        .toList();
    // log('Saving TOTP items: ${json.encode(jsonList)}'); // Log before encryption
    final String encryptedTotpItems = EncryptionUtil.encrypt(
      json.encode(jsonList),
    );
    await _secureStorage.write(key: _storageKey, value: encryptedTotpItems);
  }

  Future<void> addTotpItem(TotpItem newItem) async {
    final List<TotpItem> currentItems = await loadTotpItems();
    final TotpItem itemWithId = TotpItem(
      id: _uuid.v4(),
      serviceName: newItem.serviceName,
      username: newItem.username,
      secret: newItem.secret,
      category: newItem.category, // Include the category field
    );
    currentItems.add(itemWithId);
    await saveTotpItems(currentItems);
  }

  Future<void> updateTotpItem(TotpItem updatedItem) async {
    List<TotpItem> currentItems = await loadTotpItems();
    final int index = currentItems.indexWhere(
      (item) => item.id == updatedItem.id,
    );
    if (index != -1) {
      currentItems[index] = updatedItem;
      await saveTotpItems(currentItems);
    }
  }

  Future<void> deleteTotpItem(String id) async {
    List<TotpItem> currentItems = await loadTotpItems();
    currentItems.removeWhere((item) => item.id == id);
    await saveTotpItems(currentItems);
  }

  Future<bool> doesTotpItemExist(TotpItem newItem) async {
    final List<TotpItem> currentItems = await loadTotpItems();
    return currentItems.any(
      (item) =>
          item.serviceName == newItem.serviceName &&
          item.username == newItem.username &&
          item.secret == newItem.secret,
    );
  }
}
