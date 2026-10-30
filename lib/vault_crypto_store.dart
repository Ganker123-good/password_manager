import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'vault_models.dart';

abstract interface class VaultKeyStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class PlatformVaultKeyStorage implements VaultKeyStorage {
  PlatformVaultKeyStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class VaultAuthenticationException implements Exception {}

class VaultStorageException implements Exception {
  const VaultStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

class EncryptedVaultStore {
  static const int _formatVersion = 2;
  static const int _nonceLength = 12;
  static const int _keyLength = 32;
  static const String _keyName = 'password_manager_vault_key_v2';
  static const List<int> _associatedData = [
    0x70,
    0x61,
    0x73,
    0x73,
    0x77,
    0x6f,
    0x72,
    0x64,
    0x5f,
    0x6d,
    0x61,
    0x6e,
    0x61,
    0x67,
    0x65,
    0x72,
    0x3a,
    0x76,
    0x32,
  ];

  EncryptedVaultStore({File? file, VaultKeyStorage? keyStorage})
    : _fileOverride = file,
      _keyStorage = keyStorage ?? PlatformVaultKeyStorage();

  final File? _fileOverride;
  final VaultKeyStorage _keyStorage;
  final _cipher = AesGcm.with256bits();
  final _random = Random.secure();
  SecretKey? _key;
  late final Future<File> _vaultFile = _fileOverride == null
      ? _resolveFile()
      : Future<File>.value(_fileOverride);

  Future<File> _resolveFile() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}vault.enc.json');
  }

  Future<File> _backupFile() async {
    final file = await _vaultFile;
    return File('${file.path}.bak');
  }

  /// Opens the vault without asking the user for a separate app password.
  /// The random key is protected by the platform secure-storage facility.
  Future<VaultContents> open() async {
    final file = await _vaultFile;
    final backup = await _backupFile();
    final encodedKey = await _keyStorage.read(_keyName);

    if (encodedKey == null) {
      if (await file.exists() || await backup.exists()) {
        throw const VaultStorageException(
          'The secure key for this encrypted vault is missing.',
        );
      }
      final keyBytes = _randomBytes(_keyLength);
      final key = SecretKey(keyBytes);
      await _keyStorage.write(_keyName, base64Encode(keyBytes));
      try {
        const emptyVault = VaultContents(entries: [], trash: []);
        await _writeEncryptedFile(file, key, emptyVault);
      } catch (_) {
        await _keyStorage.delete(_keyName);
        rethrow;
      }
      _key = key;
      return const VaultContents(entries: [], trash: []);
    }

    final List<int> keyBytes;
    try {
      keyBytes = base64Decode(encodedKey);
    } catch (_) {
      throw const VaultStorageException(
        'The device secure-storage key is damaged.',
      );
    }
    if (keyBytes.length != _keyLength) {
      throw const VaultStorageException(
        'The device secure-storage key is invalid.',
      );
    }
    final key = SecretKey(keyBytes);
    final source = await file.exists() ? file : backup;
    if (!await source.exists()) {
      throw const VaultStorageException('The encrypted vault file is missing.');
    }
    final contents = await _readEncryptedFile(source, key);
    _key = key;
    return contents;
  }

  Future<VaultContents> _readEncryptedFile(File source, SecretKey key) async {
    final Map<String, dynamic> envelope;
    try {
      envelope =
          jsonDecode(await source.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      throw const VaultStorageException('Encrypted vault file is damaged.');
    }
    try {
      if (envelope['formatVersion'] != _formatVersion ||
          envelope['cipher'] != 'AES-256-GCM') {
        throw const VaultStorageException('Unsupported vault format.');
      }
      final nonce = base64Decode(envelope['nonce'] as String);
      final mac = base64Decode(envelope['mac'] as String);
      final ciphertext = base64Decode(envelope['ciphertext'] as String);
      if (nonce.length != _nonceLength || mac.length != 16) {
        throw const VaultStorageException('Encrypted vault file is damaged.');
      }
      final cleartext = await _cipher.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: _associatedData,
      );
      final decoded =
          jsonDecode(utf8.decode(cleartext)) as Map<String, dynamic>;
      return VaultContents.fromJson(decoded);
    } on VaultStorageException {
      rethrow;
    } on SecretBoxAuthenticationError {
      throw VaultAuthenticationException();
    } catch (_) {
      throw const VaultStorageException(
        'Encrypted vault file is damaged or unreadable.',
      );
    }
  }

  Future<void> save(VaultContents contents) async {
    final key = _key;
    if (key == null) throw const VaultStorageException('Vault is not open.');
    final file = await _vaultFile;
    if (!await file.exists() && !await (await _backupFile()).exists()) {
      throw const VaultStorageException('Encrypted vault file was not found.');
    }
    await _writeEncryptedFile(file, key, contents);
  }

  List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));

  Future<void> _writeEncryptedFile(
    File file,
    SecretKey key,
    VaultContents contents,
  ) async {
    final encrypted = await _cipher.encrypt(
      utf8.encode(jsonEncode(contents.toJson())),
      secretKey: key,
      nonce: _randomBytes(_nonceLength),
      aad: _associatedData,
    );
    final envelope = {
      'formatVersion': _formatVersion,
      'cipher': 'AES-256-GCM',
      'nonce': base64Encode(encrypted.nonce),
      'ciphertext': base64Encode(encrypted.cipherText),
      'mac': base64Encode(encrypted.mac.bytes),
    };
    final temporary = File('${file.path}.tmp');
    final backup = await _backupFile();
    await temporary.writeAsString(jsonEncode(envelope), flush: true);
    if (await file.exists()) {
      if (await backup.exists()) await backup.delete();
      await file.rename(backup.path);
    }
    try {
      try {
        await temporary.rename(file.path);
      } on FileSystemException {
        await temporary.copy(file.path);
        await temporary.delete();
      }
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (!await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }

  void close() {
    _key = null;
  }
}
