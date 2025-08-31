import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:totp/src/core/services/qr_code_processor_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  final QrCodeProcessorService _qrCodeProcessorService = QrCodeProcessorService();
  final MobileScannerController _cameraController = MobileScannerController();

  final ValueNotifier<bool> _isControllerReady = ValueNotifier<bool>(false);
  bool _processing = false; // Prevents handling multiple detections
  bool _torchEnabled = false;
  bool _hasCameraPermission = false;
  bool _scannerStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureCameraPermissionAndStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _cameraController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cameraController.stop();
        break;
      default:
        _cameraController.stop();
    }
  }

  Future<void> _ensureCameraPermissionAndStart() async {
    final PermissionStatus status = await Permission.camera.status;

    // update tracked permission state
    _hasCameraPermission = status.isGranted;
    setState(() {});

    if (status.isGranted) {
      if (mounted) _isControllerReady.value = true;
      return;
    }

    if (status.isDenied) {
      final PermissionStatus newStatus = await Permission.camera.request();
      if (newStatus.isGranted) {
        _hasCameraPermission = true;
        setState(() {});
      }
      if (mounted) _isControllerReady.value = true;
      return;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      // Can't request; let UI show an explanation and a button to open settings
      if (mounted) {
        _isControllerReady.value = true;
        _hasCameraPermission = false;
        setState(() {});
      }
      return;
    }
  }

  Future<void> _handleBarcode(String qrData) async {
    if (_processing) return;
    _processing = true;

    try {
      final result = await _qrCodeProcessorService.processQrCode(qrData);

      switch (result.type) {
        case QrCodeProcessResultType.success:
          if (!mounted) return;
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add TOTP Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service: ${result.totpItem!.serviceName}'),
                  Text('Account: ${result.totpItem!.username}'),
                  const SizedBox(height: 8),
                  const Text('Do you want to add this account?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => context.pop(true),
                  child: const Text('Add'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await _qrCodeProcessorService.addTotpItem(result.totpItem!);
            if (!mounted) return;
            context.pop(true);
          } else {
            if (mounted) {
              try {
                await _cameraController.start();
              } catch (_) {}
            }
          }
          break;
        case QrCodeProcessResultType.invalidFormat:
        case QrCodeProcessResultType.noSecret:
        case QrCodeProcessResultType.error:
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text(result.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (mounted) {
            try {
              await _cameraController.start();
            } catch (_) {}
          }
          break;
        case QrCodeProcessResultType.duplicate:
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Account Already Exists'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service: ${result.totpItem!.serviceName}'),
                  Text('Account: ${result.totpItem!.username}'),
                  const SizedBox(height: 8),
                  const Text('This account is already in your list.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (mounted) {
            try {
              await _cameraController.start();
            } catch (_) {}
          }
          break;
      }
    } finally {
      _processing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              try {
                await _cameraController.toggleTorch();
                setState(() {
                  _torchEnabled = !_torchEnabled;
                });
              } catch (e) {
                debugPrint('Torch toggle error: $e');
              }
            },
            tooltip: 'Toggle flash',
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isControllerReady,
        builder: (context, ready, child) {
          if (!ready) return const Center(child: CircularProgressIndicator());

          // If permission is denied, show a helpful message with settings button
          if (!_hasCameraPermission) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Camera permission is required to scan QR codes.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Try requesting again
                        final status = await Permission.camera.request();
                        if (status.isGranted) {
                          _hasCameraPermission = true;
                        } else if (status.isPermanentlyDenied) {
                          // Open app settings and re-check permission after returning
                          await openAppSettings();
                          final PermissionStatus after =
                              await Permission.camera.status;
                          _hasCameraPermission = after.isGranted;
                        }
                        setState(() {});
                      },
                      child: const Text('Request permission'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await openAppSettings();
                        final PermissionStatus after =
                            await Permission.camera.status;
                        _hasCameraPermission = after.isGranted;
                        setState(() {});
                      },
                      child: const Text('Open system settings'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!_scannerStarted) {
            _scannerStarted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                try {
                  await _cameraController.start();
                } catch (e) {
                  debugPrint('Camera start error: $e');
                }
              }
            });
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _cameraController,
                fit: BoxFit.cover,
                onDetect: (capture) async {
                  if (capture.barcodes.isEmpty) return;
                  final Barcode barcode = capture.barcodes.first;
                  final String? raw = barcode.rawValue;
                  if (raw == null || raw.isEmpty) return;

                  try {
                    await _cameraController.stop();
                  } catch (_) {}

                  await _handleBarcode(raw);
                },
              ),

              // Simple center overlay rectangle
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
