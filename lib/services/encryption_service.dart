import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';

class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List iv;

  EncryptedData({required this.ciphertext, required this.iv});

  String toBase64() {
    final bytes = Uint8List(2 + iv.length + ciphertext.length);
    final ivLen = iv.length;
    bytes[0] = (ivLen >> 8) & 0xFF;
    bytes[1] = ivLen & 0xFF;
    bytes.setAll(2, iv);
    bytes.setAll(2 + ivLen, ciphertext);
    return base64.encode(bytes);
  }

  factory EncryptedData.fromBase64(String encoded) {
    final bytes = base64.decode(encoded);
    final ivLen = (bytes[0] << 8) | bytes[1];
    final iv = Uint8List.fromList(bytes.sublist(2, 2 + ivLen));
    final ciphertext = Uint8List.fromList(bytes.sublist(2 + ivLen));
    return EncryptedData(ciphertext: ciphertext, iv: iv);
  }
}

class EncryptionService {
  Future<Uint8List> deriveKey(String password, List<int> salt) async {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    derivator.init(Pbkdf2Parameters(
      Uint8List.fromList(salt),
      AppConstants.pbkdf2Iterations,
      AppConstants.aesKeyLength,
    ));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  Future<EncryptedData> encrypt(String plaintext, Uint8List key) async {
    try {
      final iv = generateIv();
      final cipher = _createCipher(true, key, iv);
      final inputBytes = Uint8List.fromList(utf8.encode(plaintext));
      final ciphertext = cipher.process(inputBytes);
      return EncryptedData(ciphertext: ciphertext, iv: iv);
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  Future<String> decrypt(EncryptedData data, Uint8List key) async {
    try {
      final cipher = _createCipher(false, key, data.iv);
      final plaintextBytes = cipher.process(data.ciphertext);
      return utf8.decode(plaintextBytes);
    } catch (e) {
      throw EncryptionException('Decryption failed. Check your master password.');
    }
  }

  List<int> generateSalt() {
    return _generateRandomBytes(32).toList();
  }

  Uint8List generateIv() {
    return _generateRandomBytes(AppConstants.ivLength);
  }

  GCMBlockCipher _createCipher(bool forEncryption, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine());
    cipher.init(
      forEncryption,
      AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)),
    );
    return cipher;
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
}
