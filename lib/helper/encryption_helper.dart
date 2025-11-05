import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EncryptionHelper {
  static final _secureStorage = const FlutterSecureStorage();
  static const _keyName = 'encryption_key';
  static Encrypter? _cachedEncrypter;
  static String? _cachedKey;

  static Future<String> _getOrCreateKey() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    // Try secure storage first
    String? keyString = await _secureStorage.read(key: _keyName);
    
    if (keyString == null) {
      // Generate new key
      final key = Key.fromSecureRandom(32);
      keyString = base64UrlEncode(key.bytes);
      
      // Save to secure storage
      await _secureStorage.write(key: _keyName, value: keyString);
      
      // Save to Firebase
      try {
        final dbRef = FirebaseDatabase.instance.ref("users/${user.uid}/encryption_key");
        await dbRef.set(keyString);
      } catch (e) {
        print("Failed to save key to Firebase: $e");
      }
    }

    _cachedKey = keyString;
    return keyString;
  }

  static Future<Encrypter> getEncrypter() async {
    if (_cachedEncrypter != null) return _cachedEncrypter!;
    
    final keyString = await _getOrCreateKey();
    final key = Key.fromBase64(keyString);
    _cachedEncrypter = Encrypter(AES(key));
    return _cachedEncrypter!;
  }

  static IV generateIV() => IV.fromSecureRandom(16);

  static Future<Map<String, String>> encrypt(String plainText) async {
    final encrypter = await getEncrypter();
    final iv = generateIV();
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return {
      'encrypted': encrypted.base64,
      'iv': base64UrlEncode(iv.bytes),
    };
  }

  static Future<String> decrypt(String encryptedText, String ivBase64) async {
    final encrypter = await getEncrypter();
    final iv = IV.fromBase64(ivBase64);
    return encrypter.decrypt64(encryptedText, iv: iv);
  }

  static void clearCache() {
    _cachedEncrypter = null;
    _cachedKey = null;
  }
}