import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:totp/src/core/services/settings_service.dart';
import 'package:totp/src/core/services/auth_service.dart';
import 'package:totp/src/core/services/data_management_service.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/features/settings/presentation/widgets/performance_dashboard.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PackageInfo _packageInfo;
  final SettingsService _settingsService = SettingsService();
  final AuthService _authService = AuthService();
  final DataManagementService _dataManagementService = DataManagementService();

  bool _isLoading = true;
  bool _copyTotpOnTap = true;
  int _totpRefreshInterval = 30; // Default value
  bool _biometricAuthEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settingsService.init();
    _packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      _copyTotpOnTap = _settingsService.getCopyTotpOnTap();
      _totpRefreshInterval = _settingsService.getTotpRefreshInterval();
      // Await the Future<bool> from getBiometricAuthEnabled()
      _settingsService.getBiometricAuthEnabled().then((value) {
        setState(() {
          _biometricAuthEnabled = value;
        });
      });
      _isLoading = false;
    });
  }

  Future<void> _setBiometricAuth(bool value) async {
    if (value) {
      bool authenticated = await _authService.authenticateWithBiometrics();
      if (authenticated) {
        await _settingsService.setBiometricAuthEnabled(true);
        setState(() {
          _biometricAuthEnabled = true;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication cancelled or failed.'),
            ),
          );
        }
        setState(() {
          _biometricAuthEnabled = false;
        });
      }
    } else {
      await _settingsService.setBiometricAuthEnabled(false);
      setState(() {
        _biometricAuthEnabled = false;
      });
    }
  }

  Future<void> _setCopyTotpOnTap(bool value) async {
    setState(() {
      _copyTotpOnTap = value;
    });
    await _settingsService.setCopyTotpOnTap(value);
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
      await _settingsService.setTotpRefreshInterval(newInterval);
    }
  }

  Future<void> _exportAccounts() async {
    try {
      // First check if there are any accounts to export
      final List<TotpItem> items = await _dataManagementService
          .loadTotpItemsForCheck();
      if (items.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No accounts available to export')),
          );
        }
        return;
      }

      await _dataManagementService.exportAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accounts exported successfully!')),
        );
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
      final int newItemsCount = await _dataManagementService.importAccounts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$newItemsCount new accounts imported successfully!'),
          ),
        );
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

                // Security Section
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Security',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Enable Biometric Authentication'),
                  subtitle: const Text(
                    'Use fingerprint or face recognition to unlock the app',
                  ),
                  value: _biometricAuthEnabled,
                  onChanged: _setBiometricAuth,
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

                // Development Section
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Development',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  title: const Text('Performance Dashboard'),
                  subtitle: const Text('View app performance metrics'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PerformanceDashboard(),
                      ),
                    );
                  },
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
