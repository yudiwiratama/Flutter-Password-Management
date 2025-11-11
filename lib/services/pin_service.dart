import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService {
  PinService._internal();

  static final PinService instance = PinService._internal();

  static const String _pinKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _lockedKey = 'pin_locked';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> hasPin() async {
    final prefs = await _preferences;
    return prefs.containsKey(_pinKey);
  }

  Future<void> setPin(String pin, {String? saltBase64}) async {
    final prefs = await _preferences;
    final salt = saltBase64 ?? _generateSalt();
    await prefs.setString(_pinKey, hashPin(pin));
    await prefs.setString(_pinSaltKey, salt);
    await setLocked(false);
  }

  Future<String?> getPinHash() async {
    final prefs = await _preferences;
    return prefs.getString(_pinKey);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await _preferences;
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) {
      return false;
    }
    return storedHash == hashPin(pin);
  }

  Future<String?> getPinSalt() async {
    final prefs = await _preferences;
    return prefs.getString(_pinSaltKey);
  }

  Future<void> clearPin() async {
    final prefs = await _preferences;
    await prefs.remove(_pinKey);
    await prefs.remove(_pinSaltKey);
    await prefs.remove(_lockedKey);
  }

  Future<void> setPinFromBackup({
    String? hash,
    String? salt,
  }) async {
    final prefs = await _preferences;
    if (hash == null || hash.isEmpty) {
      await prefs.remove(_pinKey);
    } else {
      await prefs.setString(_pinKey, hash);
    }
    if (salt == null || salt.isEmpty) {
      await prefs.remove(_pinSaltKey);
    } else {
      await prefs.setString(_pinSaltKey, salt);
    }
  }

  Future<void> setLocked(bool locked) async {
    final prefs = await _preferences;
    await prefs.setBool(_lockedKey, locked);
  }

  Future<bool> isLocked() async {
    final prefs = await _preferences;
    return prefs.getBool(_lockedKey) ?? true;
  }

  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(Uint8List.fromList(bytes));
  }
}

