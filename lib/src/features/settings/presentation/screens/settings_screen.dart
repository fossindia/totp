// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Add this import

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  late PackageInfo _packageInfo;

  bool _isLoading = true;
  bool _copyTotpOnTap = true;
  int _totpRefreshInterval = 30; // Default value

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _copyTotpOnTap = _prefs.getBool('copyTotpOnTap') ?? true;
      _totpRefreshInterval = _prefs.getInt('totpRefreshInterval') ?? 30;
      _isLoading = false;
    });
  }

  Future<void> _setCopyTotpOnTap(bool value) async {
    setState(() {
      _copyTotpOnTap = value;
    });
    await _prefs.setBool('copyTotpOnTap', value);
  }

  Future<void> _showRefreshIntervalDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController(
      text: _totpRefreshInterval.toString(),
    );

    final newInterval = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set TOTP Refresh Interval'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter interval in seconds (e.g., 30)',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                final int? parsedInterval = int.tryParse(controller.text);
                if (parsedInterval != null && parsedInterval > 0) {
                  Navigator.of(context).pop(parsedInterval);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    if (newInterval != null) {
      setState(() {
        _totpRefreshInterval = newInterval;
      });
      await _prefs.setInt('totpRefreshInterval', newInterval);
    }
  }

  Future<void> _exportAccounts() async {
    try {
      final TotpManager totpManager = TotpManager();
      final List<TotpItem> items = await totpManager.loadTotpItems();
      final String jsonString = json.encode(
        items.map((item) => item.toJson()).toList(),
      );
      final Uint8List jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'totp_accounts.json',
        bytes: jsonBytes, // Pass bytes directly
      );

      if (outputFile != null) {
        // File is already saved by FilePicker when bytes are provided
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Accounts exported successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting accounts: $e')));
      }
    }
  }

  Future<void> _importAccounts() async {
    try {
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

        final TotpManager totpManager = TotpManager();
        int newItemsCount = 0;
        for (final item in importedItems) {
          final bool itemExists = await totpManager.doesTotpItemExist(item);
          if (!itemExists) {
            await totpManager.addTotpItem(item);
            newItemsCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$newItemsCount new accounts imported successfully!',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing accounts: $e')));
      }
    }
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // TOTP Display & Behavior
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'TOTP Display & Behavior',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Copy TOTP on Tap'),
                  value: _copyTotpOnTap,
                  onChanged: _setCopyTotpOnTap,
                ),
                ListTile(
                  title: const Text('TOTP Refresh Interval'),
                  subtitle: Text('$_totpRefreshInterval seconds'),
                  onTap: () => _showRefreshIntervalDialog(context),
                ),

                // Data Management
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  title: const Text('Export Accounts'),
                  onTap: _exportAccounts,
                ),
                ListTile(
                  title: const Text('Import Accounts'),
                  onTap: _importAccounts,
                ),

                // About Section
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  title: const Text('App Version'),
                  subtitle: Text(_packageInfo.version),
                ),
                ListTile(
                  title: const Text('Privacy Policy'),
                  onTap: () =>
                      _launchURL('https://fossindia.pages.dev/privacy_policy/'),
                ),
                ListTile(
                  title: const Text('Terms of Service'),
                  onTap: () => _launchURL(
                    'https://fossindia.pages.dev/terms_of_service/',
                  ),
                ),
                ListTile(
                  title: const Text('Open Source Licenses'),
                  onTap: () {
                    showLicensePage(context: context);
                  },
                ),
              ],
            ),
    );
  }
}
