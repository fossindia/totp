import 'package:flutter/material.dart';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/services/auth_service.dart';

class PinEntryDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool showBiometricOption;
  final VoidCallback? onBiometricPressed;

  const PinEntryDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.showBiometricOption = false,
    this.onBiometricPressed,
  });

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  int _attemptsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _loadAttemptsRemaining();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadAttemptsRemaining() async {
    final status = await _authService.getAuthStatus();
    setState(() {
      _attemptsRemaining = status.attemptsRemaining;
    });
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();

    if (pin.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your PIN';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.verifyPin(pin);

      if (result.isSuccessful) {
        // PIN is correct
        if (mounted) {
          Navigator.of(context).pop(true); // Return success
        }
      } else if (result.pinNotSetup) {
        setState(() {
          _errorMessage = 'PIN is not set up';
        });
      } else if (result.lockoutRemaining != null) {
        // User is locked out
        final minutes = result.lockoutRemaining!.inMinutes;
        final seconds = result.lockoutRemaining!.inSeconds % 60;
        setState(() {
          _errorMessage =
              'Too many failed attempts. Try again in ${minutes}m ${seconds}s';
        });
        if (mounted) {
          Navigator.of(context).pop(false); // Return failure due to lockout
        }
      } else {
        // PIN is incorrect
        await _loadAttemptsRemaining();
        setState(() {
          _errorMessage =
              'Incorrect PIN. ${result.attemptsRemaining ?? _attemptsRemaining} attempts remaining.';
          _pinController.clear();
        });

        if ((result.attemptsRemaining ?? _attemptsRemaining) <= 0) {
          if (mounted) {
            Navigator.of(context).pop(false); // Return failure due to lockout
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying PIN: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onNumberPressed(String number) {
    if (_pinController.text.length < 8) {
      _pinController.text += number;
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _onBackspacePressed() {
    if (_pinController.text.isNotEmpty) {
      _pinController.text = _pinController.text.substring(
        0,
        _pinController.text.length - 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              widget.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // PIN dots display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (index) {
                final isFilled = index < _pinController.text.length;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? AppColors.primaryPurple
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.2),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Number pad
            Column(
              children: [
                // Rows 1-3 (numbers 1-9)
                for (int row = 0; row < 3; row++)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int col = 1; col <= 3; col++)
                        _buildNumberButton((row * 3 + col).toString()),
                    ],
                  ),

                // Row 4 (0, backspace)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildNumberButton('0'), _buildBackspaceButton()],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Biometric option
            if (widget.showBiometricOption && widget.onBiometricPressed != null)
              TextButton.icon(
                onPressed: widget.onBiometricPressed,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use Biometric'),
              ),

            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          number,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(4),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onBackspacePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Icon(Icons.backspace),
      ),
    );
  }
}
