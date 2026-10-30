import 'dart:convert';
import 'dart:typed_data';

class VaultEntry {
  const VaultEntry({
    this.iconBytes,
    this.name = '',
    this.account = '',
    this.password = '',
    this.gesturePattern = '',
  });

  final Uint8List? iconBytes;
  final String name;
  final String account;
  final String password;
  final String gesturePattern;

  Map<String, Object?> toJson() => {
    'name': name,
    'account': account,
    'password': password,
    'gesturePattern': gesturePattern,
    'iconBytes': iconBytes == null ? null : base64Encode(iconBytes!),
  };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
    name: json['name'] as String? ?? '',
    account: json['account'] as String? ?? '',
    password: json['password'] as String? ?? '',
    gesturePattern: json['gesturePattern'] as String? ?? '',
    iconBytes: json['iconBytes'] == null
        ? null
        : Uint8List.fromList(base64Decode(json['iconBytes'] as String)),
  );
}

class VaultContents {
  const VaultContents({required this.entries, required this.trash});

  final List<VaultEntry> entries;
  final List<VaultEntry> trash;

  Map<String, Object?> toJson() => {
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'trash': trash.map((entry) => entry.toJson()).toList(),
  };

  factory VaultContents.fromJson(Map<String, dynamic> json) => VaultContents(
    entries: (json['entries'] as List<dynamic>? ?? const [])
        .map((entry) => VaultEntry.fromJson(entry as Map<String, dynamic>))
        .toList(),
    trash: (json['trash'] as List<dynamic>? ?? const [])
        .map((entry) => VaultEntry.fromJson(entry as Map<String, dynamic>))
        .toList(),
  );
}
