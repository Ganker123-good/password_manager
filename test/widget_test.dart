import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/vault_models.dart';

void main() {
  test('empty vault model serializes both lists', () {
    const vault = VaultContents(entries: [], trash: []);
    expect(VaultContents.fromJson(vault.toJson()).entries, isEmpty);
    expect(VaultContents.fromJson(vault.toJson()).trash, isEmpty);
  });
}
