import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../services/pin_service.dart';
import '../services/security_service.dart';
import 'password_list_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({
    super.key,
    this.isInitialSetup = false,
  });

  final bool isInitialSetup;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String? _validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN tidak boleh kosong';
    }
    if (value.length < 4) {
      return 'PIN minimal 4 digit';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'PIN hanya boleh angka';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi PIN tidak boleh kosong';
    }
    if (value != _pinController.text) {
      return 'PIN tidak sama';
    }
    return null;
  }

  Future<void> _savePin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newPin = _pinController.text.trim();

      if (widget.isInitialSetup) {
        await SecurityService.instance.initializeNewPin(newPin);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN berhasil dibuat')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PasswordListScreen(),
          ),
        );
      } else {
        final currentPin = _currentPinController.text.trim();
        final isValid = await PinService.instance.verifyPin(currentPin);
        if (!isValid) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN lama tidak valid')),
          );
          return;
        }

        await SecurityService.instance.unlockWithPin(currentPin);
        final passwords = await DatabaseHelper.instance.getAllPasswords();

        final updated = await SecurityService.instance.changePin(
          currentPin: currentPin,
          newPin: newPin,
        );

        if (!mounted) return;

        if (updated) {
          await DatabaseHelper.instance.importPasswords(passwords);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN berhasil diperbarui')),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN lama tidak valid')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInitial = widget.isInitialSetup;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isInitial,
        title: Text(isInitial ? 'Buat PIN' : 'Ubah PIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isInitial
                    ? 'Buat PIN keamanan untuk mengakses aplikasi.'
                    : 'Masukkan PIN lama dan buat PIN baru.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (!isInitial) ...[
                TextFormField(
                  controller: _currentPinController,
                  decoration: const InputDecoration(
                    labelText: 'PIN Lama',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_open),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: _validatePin,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: 'PIN Baru',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: _validatePin,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPinController,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: _validateConfirmation,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _savePin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isInitial ? 'Simpan PIN' : 'Perbarui PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

