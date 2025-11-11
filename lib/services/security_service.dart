import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'pin_service.dart';

class SecurityService {
  SecurityService._internal();

  static final SecurityService instance = SecurityService._internal();

  final _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  final AesGcm _aesGcm = AesGcm.with256bits();
  SecretKey? _encryptionKey;

  bool get isUnlocked => _encryptionKey != null;

  void lock() {
    _encryptionKey = null;
  }

  Future<void> unlockWithPin(String pin) async {
    final saltBase64 = await PinService.instance.getPinSalt();
    if (saltBase64 == null) {
      throw StateError('PIN belum diatur.');
    }
    final saltBytes = base64Decode(saltBase64);
    _encryptionKey = await _deriveKey(pin, saltBytes);
  }

  Future<void> initializeNewPin(String pin) async {
    final saltBytes = _generateSalt();
    final saltBase64 = base64Encode(saltBytes);
    await PinService.instance.setPin(pin, saltBase64: saltBase64);
    _encryptionKey = await _deriveKey(pin, saltBytes);
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final isValid = await PinService.instance.verifyPin(currentPin);
    if (!isValid) {
      return false;
    }

    final saltBytes = _generateSalt();
    final saltBase64 = base64Encode(saltBytes);
    await PinService.instance.setPin(newPin, saltBase64: saltBase64);

    _encryptionKey = await _deriveKey(newPin, saltBytes);
    return true;
  }

  Future<String> encrypt(String text) async {
    if (_encryptionKey == null) {
      throw StateError('Aplikasi belum terbuka dengan PIN.');
    }

    final nonce = _aesGcm.newNonce();
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(text),
      secretKey: _encryptionKey!,
      nonce: nonce,
    );

    final payload = {
      'nonce': base64Encode(secretBox.nonce),
      'cipher': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return jsonEncode(payload);
  }

  Future<String> decrypt(String encrypted) async {
    if (_encryptionKey == null) {
      throw StateError('Aplikasi belum terbuka dengan PIN.');
    }

    final map = jsonDecode(encrypted) as Map<String, dynamic>;
    final nonce = base64Decode(map['nonce'] as String);
    final cipher = base64Decode(map['cipher'] as String);
    final macBytes = base64Decode(map['mac'] as String);

    final secretBox = SecretBox(
      cipher,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: _encryptionKey!,
    );
    return utf8.decode(clearBytes);
  }

  Uint8List _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  Future<SecretKey> _deriveKey(String pin, List<int> salt) {
    final secretKey = SecretKey(utf8.encode(pin));
    return _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
  }
}

