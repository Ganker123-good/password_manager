import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/vault_crypto_store.dart';
import 'package:password_manager/vault_models.dart';

class _MemoryKeyStorage implements VaultKeyStorage {
  String? value;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String value) async {
    this.value = value;
  }

  @override
  Future<void> delete(String key) async {
    value = null;
  }
}

void main() {
  late Directory tempDirectory;
  late File vaultFile;
  late _MemoryKeyStorage keyStorage;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'password_manager_test_',
    );
    vaultFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}vault.enc.json',
    );
    keyStorage = _MemoryKeyStorage();
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'auto-opens an encrypted vault and restores it after reopening',
    () async {
      final firstStore = EncryptedVaultStore(
        file: vaultFile,
        keyStorage: keyStorage,
      );
      expect((await firstStore.open()).entries, isEmpty);
      final contents = VaultContents(
        entries: [
          const VaultEntry(
            name: 'Email',
            account: 'private@example.test',
            password: 'not-a-real-password-123',
            gesturePattern: '0,1,4,7',
          ),
        ],
        trash: [const VaultEntry(name: 'Old account', password: 'discard-me')],
      );
      await firstStore.save(contents);

      final fileText = await vaultFile.readAsString();
      expect(fileText, isNot(contains('private@example.test')));
      expect(fileText, isNot(contains('not-a-real-password-123')));
      expect(fileText, isNot(contains('gesturePattern')));

      final restored = await EncryptedVaultStore(
        file: vaultFile,
        keyStorage: keyStorage,
      ).open();
      expect(restored.entries.single.name, 'Email');
      expect(restored.entries.single.account, 'private@example.test');
      expect(restored.entries.single.password, 'not-a-real-password-123');
      expect(restored.entries.single.gesturePattern, '0,1,4,7');
      expect(restored.trash.single.name, 'Old account');
    },
  );

  test('rejects a changed or damaged device key', () async {
    await EncryptedVaultStore(file: vaultFile, keyStorage: keyStorage).open();
    keyStorage.value = base64Encode(List<int>.filled(32, 7));
    await expectLater(
      EncryptedVaultStore(file: vaultFile, keyStorage: keyStorage).open(),
      throwsA(isA<VaultAuthenticationException>()),
    );
  });

  test('rejects a damaged vault envelope', () async {
    await EncryptedVaultStore(file: vaultFile, keyStorage: keyStorage).open();
    await vaultFile.writeAsString(jsonEncode({'formatVersion': 999}));
    await expectLater(
      EncryptedVaultStore(file: vaultFile, keyStorage: keyStorage).open(),
      throwsA(isA<VaultStorageException>()),
    );
  });
}
