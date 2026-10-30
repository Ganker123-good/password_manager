# Password Manager

A Flutter password manager prototype for Windows, Android, and iOS. The interface supports Chinese and English.

> **Prototype notice:** The app currently opens automatically without a separate master password. Anyone using the same unlocked device account may be able to open the vault. Vault data is encrypted at rest, but this project does not yet provide cross-device sync, encrypted export/import, or a backup and recovery flow. Do not rely on it as the only copy of important credentials.

## Features

- Create, edit, and view password entries.
- Store account names, passwords, and gesture patterns.
- Copy account names and passwords.
- Move entries to Trash, restore them, or permanently delete them.
- Encrypt the local vault with AES-256-GCM.
- Store the vault key using the platform secure-storage facility.
- Automatically unlock on the same device without another app password.

## Run on Windows

Requirements: Flutter SDK and Visual Studio with the **Desktop development with C++** workload.

```powershell
flutter pub get
flutter run -d windows
```

To build a Windows release:

```powershell
flutter build windows --release
```

The release bundle is created under `build/windows/x64/runner/Release/`. Distribute the whole folder, including its `data` directory and required DLL files; do not distribute only the `.exe`.

## Build for iOS

Building and signing the iOS app requires macOS and Xcode. The Windows project folder alone cannot produce an iPhone installable app. The iOS vault is stored separately on each device; this prototype does not synchronize entries between Windows and iPhone.

## Data and security

Vault contents are encrypted locally. The encryption key is kept in the operating system's secure storage. Each device has its own key and vault. Reinstalling, losing device access, or losing the secure-storage key may make the vault unrecoverable. There is no recovery or cross-device transfer feature yet.

Please use fictional data while evaluating this prototype. Review the security design before using it to store real credentials.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
