import 'dart:convert';

import '../database/database_helper.dart';
import '../models/password_model.dart';
import 'pin_service.dart';
import 'security_service.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const _metaVersion = 1;

  Future<String> exportBackup() async {
    final encryptedRows = await DatabaseHelper.instance.getAllEncryptedRows();
    final pinHash = await PinService.instance.getPinHash();

    final payload = {
      'meta': {
        'version': _metaVersion,
        'generatedAt': DateTime.now().toIso8601String(),
      },
      'pinHash': pinHash,
      'pinSalt': await PinService.instance.getPinSalt(),
      'passwords': encryptedRows,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importBackup(
    String rawJson, {
    required String pin,
  }) async {
    if (rawJson.trim().isEmpty) {
      throw const FormatException('Backup tidak boleh kosong');
    }

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Format backup tidak valid');
    }

    final passwordsData = decoded['passwords'];
    if (passwordsData is! List) {
      throw const FormatException('Data password tidak ditemukan');
    }

    final passwords = passwordsData.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Item password tidak valid');
      }
      return item.map<String, dynamic>(
        (key, value) => MapEntry(key, value),
      );
    }).toList();

    final pinHash = decoded['pinHash'];
    final pinSalt = decoded['pinSalt'];
    if (pinHash != null && pinHash is! String) {
      throw const FormatException('PIN hash tidak valid');
    }
    if (pinSalt != null && pinSalt is! String) {
      throw const FormatException('PIN salt tidak valid');
    }

    if (pinHash != null) {
      final providedHash = PinService.instance.hashPin(pin);
      if (providedHash != pinHash) {
        throw const FormatException('PIN tidak cocok dengan backup');
      }
    }

    await PinService.instance.setPinFromBackup(
      hash: pinHash as String?,
      salt: pinSalt as String?,
    );
    await SecurityService.instance.unlockWithPin(pin);

    await DatabaseHelper.instance.importEncryptedRows(passwords);

    await PinService.instance.setLocked(true);
    SecurityService.instance.lock();
  }
}

