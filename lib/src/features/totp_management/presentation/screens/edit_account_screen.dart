import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:totp/src/core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';

class EditAccountScreen extends StatefulWidget {
  final TotpItem totpItem;

  const EditAccountScreen({super.key, required this.totpItem});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serviceNameController;
  late TextEditingController _usernameController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController(
      text: widget.totpItem.serviceName,
    );
    _usernameController = TextEditingController(text: widget.totpItem.username);
    _categoryController = TextEditingController(text: widget.totpItem.category);
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _usernameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState!.validate()) {
      final updatedItem = TotpItem(
        id: widget.totpItem.id,
        serviceName: _serviceNameController.text,
        username: _usernameController.text,
        secret: widget.totpItem.secret,
        category: _categoryController.text.isEmpty
            ? null
            : _categoryController.text,
      );

      final TotpManager totpManager = TotpManager();
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      await totpManager.updateTotpItem(updatedItem);

      if (!mounted) return;
      // ignore: use_build_context_synchronously
      messenger.showSnackBar(
        const SnackBar(content: Text('Account updated successfully!')),
      );
      // ignore: use_build_context_synchronously
      router.pop(true);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete this account?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      final TotpManager totpManager = TotpManager();
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.of(context);

      await totpManager.deleteTotpItem(widget.totpItem.id);

      if (!mounted) return;
      // ignore: use_build_context_synchronously
      messenger.showSnackBar(
        const SnackBar(content: Text('Account deleted successfully!')),
      );
      // ignore: use_build_context_synchronously
      router.pop(true); // Pop with true to indicate a change
    }
  }

  void _showQrCodeBottomSheet(BuildContext context) {
    final String qrData =
        'otpauth://totp/${Uri.encodeComponent(widget.totpItem.serviceName)}:${Uri.encodeComponent(widget.totpItem.username)}?secret=${Uri.encodeComponent(widget.totpItem.secret)}&issuer=${Uri.encodeComponent(widget.totpItem.serviceName)}';

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Scan this QR code with your Authenticator app',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                PrettyQrView.data(
                  data: qrData,
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(color: AppColors.white),
                    quietZone: PrettyQrQuietZone.standart,
                  ),
                ),
                Text(
                  'Service: ${widget.totpItem.serviceName}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Secret: ${widget.totpItem.secret}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              _showQrCodeBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () => _deleteAccount(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _serviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a service name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
