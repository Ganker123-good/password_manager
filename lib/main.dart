import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/material.dart' as material show Text;
import 'package:flutter/services.dart';

import 'vault_crypto_store.dart';
import 'vault_models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PasswordManagerApp());
}

final ValueNotifier<bool> _english = ValueNotifier<bool>(false);
int _clipboardCopyGeneration = 0;

Future<void> _copySensitiveValue(String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (defaultTargetPlatform != TargetPlatform.windows) return;
  final generation = ++_clipboardCopyGeneration;
  Future<void>.delayed(const Duration(seconds: 30), () async {
    if (generation != _clipboardCopyGeneration) return;
    final current = await Clipboard.getData(Clipboard.kTextPlain);
    if (current?.text == value) {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  });
}

String _tx(String value) {
  if (!_english.value) return value;
  const translations = <String, String>{
    '之后可以在回收站中恢复，或彻底删除。':
        'You can restore it from trash or permanently delete it later.',
    '请至少填写名称、账号、密码或手势密码中的一项。':
        'Enter at least a name, account, password, or gesture pattern.',
    '密码库会使用此设备的安全存储自动解锁。':
        'Your vault unlocks automatically using this device’s secure storage.',
    '条目会加密保存在此设备上，并随应用自动解锁。': 'Entries are encrypted on this device and unlock automatically with the app.',
    '密码库内容已加密保存在此设备上。': 'Your vault contents are encrypted on this device.',
    '密码库已加密保存，打开应用时会自动解锁':
        'Your encrypted vault unlocks automatically when you open the app',
    '密码库已加密保存在此设备上。': 'Your vault is encrypted on this device.',
    '无法自动打开密码库。请检查此设备的安全存储。': 'Unable to open the vault automatically. Check this device’s secure storage.',
    '重试': 'Retry',
    '密码管家': 'Password Manager',
    '原型阶段安全提示': 'Prototype safety notice',
    '你的密码，妥善管理': 'Keep your passwords organized',
    '我的密码库': 'My vault',
    '选择': 'Select',
    '取消选择': 'Cancel selection',
    '全选': 'Select all',
    '取消全选': 'Deselect all',
    '项已选': 'items selected',
    '将所选条目移入回收站？': 'Move selected items to trash?',
    '选中的条目可以在回收站恢复。': 'Selected items can be restored from Trash.',
    '密码库还是空的': 'Your vault is empty',
    '点击“添加条目”开始体验': 'Add an item to get started',
    '此操作无法撤销。': 'This action cannot be undone.',
    '回收站是空的': 'The trash is empty',
    '移到回收站？': 'Move to trash?',
    '未命名条目': 'Untitled item',
    '条目详情': 'Item details',
    '保存修改': 'Save changes',
    '选择图标图片': 'Choose icon image',
    '账号（可选，仅英文、数字和符号）': 'Account (optional: English letters, numbers, symbols)',
    '密码（可选，仅英文、数字和符号）':
        'Password (optional: English letters, numbers, symbols)',
    '手势密码（可选）': 'Gesture pattern (optional)',
    '在九宫格上滑动绘制手势': 'Draw a pattern on the 3×3 grid',
    '已录入手势密码': 'Gesture pattern recorded',
    '清除': 'Clear',
    '手势密码': 'Gesture pattern',
    '显示手势密码': 'Show gesture pattern',
    '隐藏手势密码': 'Hide gesture pattern',
    '名称（可选）': 'Name (optional)',
    '例如：邮箱': 'For example: Email',
    '此版本不会加密': 'This version does not encrypt',
    '彻底删除': 'Delete permanently',
    '移到回收站': 'Move to trash',
    '安全提示': 'Safety notice',
    '添加条目': 'Add item',
    '编辑条目': 'Edit item',
    '图片': 'Images',
    '更换图片': 'Change image',
    '移除图片': 'Remove image',
    '显示密码': 'Show password',
    '隐藏密码': 'Hide password',
    '知道了': 'Got it',
    '取消': 'Cancel',
    '创建': 'Create',
    '名称': 'Name',
    '账号': 'Account',
    '密码': 'Password',
    '编辑': 'Edit',
    '回收站': 'Trash',
    '恢复': 'Restore',
    '复制账号': 'Copy account',
    '复制密码': 'Copy password',
    '账号：': 'Account: ',
    '密码：': 'Password: ',
    '已复制': ' copied',
    '项': 'items',
  };
  var translated = value;
  for (final entry in translations.entries) {
    translated = translated.replaceAll(entry.key, entry.value);
  }
  return translated;
}

class Text extends StatelessWidget {
  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.translate = true,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool translate;

  @override
  Widget build(BuildContext context) => material.Text(
    translate ? _tx(data) : data,
    key: key,
    style: style,
    textAlign: textAlign,
    overflow: overflow,
    maxLines: maxLines,
  );
}

mixin _LocaleAware<T extends StatefulWidget> on State<T> {
  void _refreshForLanguage() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _english.addListener(_refreshForLanguage);
  }

  @override
  void dispose() {
    _english.removeListener(_refreshForLanguage);
    super.dispose();
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _english,
      builder: (context, english, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Tooltip(
          message: english ? 'Switch to Chinese' : 'Switch to English',
          child: TextButton.icon(
            onPressed: () => _english.value = !english,
            icon: const Icon(Icons.translate),
            label: Text(english ? '中文' : 'English', translate: false),
          ),
        ),
      ),
    );
  }
}

class VaultGate extends StatefulWidget {
  const VaultGate({super.key});

  @override
  State<VaultGate> createState() => _VaultGateState();
}

class _VaultGateState extends State<VaultGate> {
  final EncryptedVaultStore _store = EncryptedVaultStore();
  Future<void> _saveQueue = Future<void>.value();
  bool _loading = true;
  VaultContents? _contents;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openVault();
  }

  Future<void> _openVault() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contents = await _store.open();
      if (mounted) setState(() => _contents = contents);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '无法自动打开密码库。请检查此设备的安全存储。');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveVault(VaultContents contents) {
    final snapshot = VaultContents(
      entries: List<VaultEntry>.unmodifiable(contents.entries),
      trash: List<VaultEntry>.unmodifiable(contents.trash),
    );
    final next = _saveQueue
        .catchError((Object _) {})
        .then((_) => _store.save(snapshot));
    _saveQueue = next;
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final contents = _contents;
    if (contents != null) {
      return VaultHomePage(
        initialContents: contents,
        onVaultChanged: _saveVault,
      );
    }
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 52,
                color: Color(0xFF5267D8),
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? '无法自动打开密码库。请检查此设备的安全存储。',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: _openVault, child: Text('重试')),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordManagerApp extends StatelessWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _tx('密码管家'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5267D8)),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const VaultGate(),
    );
  }
}

class VaultHomePage extends StatefulWidget {
  const VaultHomePage({
    super.key,
    required this.initialContents,
    required this.onVaultChanged,
  });

  final VaultContents initialContents;
  final Future<void> Function(VaultContents) onVaultChanged;

  @override
  State<VaultHomePage> createState() => _VaultHomePageState();
}

class _VaultHomePageState extends State<VaultHomePage>
    with _LocaleAware<VaultHomePage> {
  late final List<VaultEntry> _entries = List.of(
    widget.initialContents.entries,
  );
  late final List<VaultEntry> _trash = List.of(widget.initialContents.trash);
  final Set<int> _selectedIndices = {};
  bool _selectionMode = false;

  Future<void> _persistVault() async {
    final contents = VaultContents(
      entries: List<VaultEntry>.of(_entries),
      trash: List<VaultEntry>.of(_trash),
    );
    try {
      await widget.onVaultChanged(contents);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加密保存成功')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加密保存失败，请检查磁盘空间后重试。')),
        );
      }
    }
  }

  Future<void> _addEntry() async {
    final entry = await showDialog<VaultEntry>(
      context: context,
      builder: (context) => const _EntryEditorDialog(),
    );
    if (entry != null && mounted) {
      setState(() => _entries.insert(0, entry));
      _persistVault();
    }
  }

  Future<void> _openEntry(int index) async {
    final entry = _entries[index];
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EntryDetailPage(
          entry: entry,
          onUpdated: (updated) {
            if (mounted && index < _entries.length) {
              setState(() => _entries[index] = updated);
              _persistVault();
            }
          },
          onMoveToTrash: (removed) {
            if (mounted && index < _entries.length) {
              setState(() {
                _entries.removeAt(index);
                _trash.insert(0, removed);
              });
              _persistVault();
            }
          },
        ),
      ),
    );
  }

  Future<void> _moveEntryToTrash(int index) async {
    final entry = _entries[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('移到回收站？'),
        content: Text(
          _english.value
              ? 'Move this item to Trash? You can restore it later.'
              : '确定将此条目移到回收站吗？之后可以恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('移到回收站'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final adjustedSelection = _selectedIndices
        .where((selectedIndex) => selectedIndex != index)
        .map(
          (selectedIndex) =>
              selectedIndex > index ? selectedIndex - 1 : selectedIndex,
        )
        .toSet();
    setState(() {
      _entries.removeAt(index);
      _trash.insert(0, entry);
      _selectedIndices
        ..clear()
        ..addAll(adjustedSelection);
      if (_entries.isEmpty) {
        _selectionMode = false;
        _selectedIndices.clear();
      }
    });
    _persistVault();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedIndices.clear();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _entries.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices
          ..clear()
          ..addAll(List<int>.generate(_entries.length, (index) => index));
      }
    });
  }

  void _toggleEntrySelection(int index) {
    setState(() {
      if (!_selectedIndices.add(index)) _selectedIndices.remove(index);
    });
  }

  Future<void> _moveSelectedToTrash() async {
    if (_selectedIndices.isEmpty) return;
    final count = _selectedIndices.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('将所选条目移入回收站？'),
        content: Text(
          _english.value
              ? 'Move $count selected items to Trash? Selected items can be restored from Trash.'
              : '将选中的$count个条目移入回收站。选中的条目可以在回收站恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('移到回收站'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final indexes = _selectedIndices.toList()..sort();
    final movingEntries = indexes.map((index) => _entries[index]).toList();
    for (final index in indexes.reversed) {
      _entries.removeAt(index);
    }
    setState(() {
      _trash.insertAll(0, movingEntries);
      _selectedIndices.clear();
      _selectionMode = false;
    });
    _persistVault();
  }

  Future<void> _openTrash() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrashPage(
          entries: List<VaultEntry>.of(_trash),
          onRestore: (entry) {
            if (!mounted) return;
            setState(() {
              _trash.remove(entry);
              _entries.insert(0, entry);
            });
            _persistVault();
          },
          onDeleteForever: (entry) {
            if (mounted) {
              setState(() => _trash.remove(entry));
              _persistVault();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('密码管家', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: _tx('回收站'),
            onPressed: _openTrash,
            icon: Badge(
              isLabelVisible: _trash.isNotEmpty,
              label: Text('${_trash.length}'),
              child: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
          const _LanguageButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5267D8), Color(0xFF7B65D6)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 18),
                      Text(
                        '你的密码，妥善管理',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '密码库会使用此设备的安全存储自动解锁。',
                        style: TextStyle(color: Colors.white, height: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '我的密码库',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_entries.isNotEmpty)
                      TextButton(
                        onPressed: _toggleSelectionMode,
                        child: Text(_selectionMode ? '取消选择' : '选择'),
                      ),
                    Text(
                      _selectionMode
                          ? '${_selectedIndices.length} 项已选'
                          : '${_entries.length} 项',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8EAF1)),
                    ),
                    child: _entries.isEmpty
                        ? _EmptyVault(onAdd: _addEntry)
                        : ListView.separated(
                            itemCount: _entries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => _EntryCard(
                              entry: _entries[index],
                              onTap: () => _openEntry(index),
                              selectionMode: _selectionMode,
                              selected: _selectedIndices.contains(index),
                              onSelect: () => _toggleEntrySelection(index),
                              onMoveToTrash: () => _moveEntryToTrash(index),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectionMode)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _toggleSelectAll,
                        icon: const Icon(Icons.select_all),
                        label: Text(
                          _selectedIndices.length == _entries.length
                              ? '取消全选'
                              : '全选',
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _selectedIndices.isEmpty
                            ? null
                            : _moveSelectedToTrash,
                        icon: const Icon(Icons.delete_outline),
                        label: Text('移到回收站'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '密码库已加密保存，打开应用时会自动解锁',
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryEditorDialog extends StatefulWidget {
  const _EntryEditorDialog({this.initialEntry});

  final VaultEntry? initialEntry;

  @override
  State<_EntryEditorDialog> createState() => _EntryEditorDialogState();
}

class _EntryEditorDialogState extends State<_EntryEditorDialog>
    with _LocaleAware<_EntryEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _accountController;
  late final TextEditingController _passwordController;
  Uint8List? _iconBytes;
  String _gesturePattern = '';
  bool _showPassword = false;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _nameController = TextEditingController(text: entry?.name ?? '');
    _accountController = TextEditingController(text: entry?.account ?? '');
    _passwordController = TextEditingController(text: entry?.password ?? '');
    _gesturePattern = entry?.gesturePattern ?? '';
    _iconBytes = entry?.iconBytes;
  }

  Future<void> _chooseIcon() async {
    final imageTypes = XTypeGroup(
      label: _tx('图片'),
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
    );
    final image = await openFile(acceptedTypeGroups: [imageTypes]);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (mounted) setState(() => _iconBytes = bytes);
  }

  void _save() {
    final name = _nameController.text.trim();
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty &&
        account.isEmpty &&
        password.isEmpty &&
        _gesturePattern.isEmpty) {
      setState(
        () => _validationMessage = _english.value
            ? 'Enter at least a name, account, password, or gesture pattern.'
            : '请至少填写名称、账号、密码或手势密码中的一项。',
      );
      return;
    }
    Navigator.pop(
      context,
      VaultEntry(
        iconBytes: _iconBytes,
        name: name,
        account: account,
        password: _passwordController.text,
        gesturePattern: _gesturePattern,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialEntry != null;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(editing ? '编辑条目' : '添加条目')),
          const _LanguageButton(),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _VaultIcon(bytes: _iconBytes, size: 52),
                  const SizedBox(width: 14),
                  OutlinedButton.icon(
                    onPressed: _chooseIcon,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_iconBytes == null ? '选择图标图片' : '更换图片'),
                  ),
                  if (_iconBytes != null)
                    IconButton(
                      tooltip: _tx('移除图片'),
                      onPressed: () => setState(() => _iconBytes = null),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _tx('名称（可选）'),
                  hintText: _tx('例如：邮箱'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _accountController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\x20-\x7E]')),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _tx('账号（可选，仅英文、数字和符号）'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                keyboardType: TextInputType.visiblePassword,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\x20-\x7E]')),
                ],
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: _tx('密码（可选，仅英文、数字和符号）'),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _tx(_showPassword ? '隐藏密码' : '显示密码'),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '手势密码（可选）',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: _GesturePatternPad(
                  pattern: _gesturePattern,
                  onChanged: (pattern) =>
                      setState(() => _gesturePattern = pattern),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _gesturePattern.isEmpty ? '在九宫格上滑动绘制手势' : '已录入手势密码',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  if (_gesturePattern.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _gesturePattern = ''),
                      child: Text('清除'),
                    ),
                ],
              ),
              if (_validationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _validationMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                '条目会加密保存在此设备上，并随应用自动解锁。',
                style: TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('取消')),
        FilledButton(onPressed: _save, child: Text(editing ? '保存修改' : '创建')),
      ],
    );
  }
}

class _GesturePatternPad extends StatefulWidget {
  const _GesturePatternPad({required this.pattern, required this.onChanged});

  final String pattern;
  final ValueChanged<String> onChanged;

  @override
  State<_GesturePatternPad> createState() => _GesturePatternPadState();
}

class _GesturePatternPadState extends State<_GesturePatternPad> {
  late List<int> _points;

  @override
  void initState() {
    super.initState();
    _points = _decodeGesturePattern(widget.pattern);
  }

  @override
  void didUpdateWidget(covariant _GesturePatternPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pattern != oldWidget.pattern &&
        widget.pattern != _encodeGesturePattern(_points)) {
      _points = _decodeGesturePattern(widget.pattern);
    }
  }

  int? _hitTest(Offset position) {
    const side = 240.0;
    const radius = 28.0;
    final column = (position.dx / (side / 3) - 0.5).round();
    final row = (position.dy / (side / 3) - 0.5).round();
    if (column < 0 || column > 2 || row < 0 || row > 2) return null;
    final center = Offset((column + 0.5) * side / 3, (row + 0.5) * side / 3);
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    if (dx * dx + dy * dy > radius * radius) return null;
    return row * 3 + column;
  }

  int _gcd(int a, int b) {
    while (b != 0) {
      final remainder = a % b;
      a = b;
      b = remainder;
    }
    return a;
  }

  void _addPoint(int point) {
    if (_points.contains(point)) return;
    if (_points.isNotEmpty) {
      final previous = _points.last;
      final previousRow = previous ~/ 3;
      final previousColumn = previous % 3;
      final row = point ~/ 3;
      final column = point % 3;
      final rowDelta = row - previousRow;
      final columnDelta = column - previousColumn;
      final steps = _gcd(rowDelta.abs(), columnDelta.abs());
      if (steps > 1) {
        for (var step = 1; step < steps; step++) {
          final intermediate =
              (previousRow + rowDelta * step ~/ steps) * 3 +
              previousColumn +
              columnDelta * step ~/ steps;
          if (!_points.contains(intermediate)) _points.add(intermediate);
        }
      }
    }
    _points.add(point);
    widget.onChanged(_encodeGesturePattern(_points));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _points = [];
        final point = _hitTest(details.localPosition);
        if (point != null) _addPoint(point);
        setState(() {});
      },
      onPanUpdate: (details) {
        final point = _hitTest(details.localPosition);
        if (point != null) _addPoint(point);
      },
      child: SizedBox(
        width: 240,
        height: 240,
        child: CustomPaint(
          painter: _GesturePatternPainter(
            points: _points.toList(),
            showPath: true,
          ),
        ),
      ),
    );
  }
}

String _encodeGesturePattern(List<int> points) => points.join(',');

List<int> _decodeGesturePattern(String pattern) => pattern
    .split(',')
    .map(int.tryParse)
    .whereType<int>()
    .where((point) => point >= 0 && point < 9)
    .toList();

class _GesturePatternPainter extends CustomPainter {
  const _GesturePatternPainter({required this.points, required this.showPath});

  final List<int> points;
  final bool showPath;

  @override
  void paint(Canvas canvas, Size size) {
    final spacingX = size.width / 3;
    final spacingY = size.height / 3;
    Offset center(int point) =>
        Offset((point % 3 + 0.5) * spacingX, (point ~/ 3 + 0.5) * spacingY);
    final selected = points.toSet();
    if (showPath && points.length > 1) {
      final pathPaint = Paint()
        ..color = const Color(0xFF5267D8)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()
        ..moveTo(center(points.first).dx, center(points.first).dy);
      for (final point in points.skip(1)) {
        path.lineTo(center(point).dx, center(point).dy);
      }
      canvas.drawPath(path, pathPaint);
    }
    for (var point = 0; point < 9; point++) {
      final isSelected = selected.contains(point);
      final paint = Paint()
        ..color = isSelected ? const Color(0xFF5267D8) : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center(point), isSelected ? 11 : 8, paint);
      canvas.drawCircle(
        center(point),
        isSelected ? 11 : 8,
        Paint()
          ..color = isSelected ? const Color(0xFF5267D8) : Colors.black38
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GesturePatternPainter oldDelegate) =>
      oldDelegate.showPath != showPath || oldDelegate.points != points;
}

class _EntryCard extends StatefulWidget {
  const _EntryCard({
    required this.entry,
    required this.onTap,
    this.selectionMode = false,
    this.selected = false,
    this.onSelect,
    this.onMoveToTrash,
  });

  final VaultEntry entry;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onMoveToTrash;

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> with _LocaleAware<_EntryCard> {
  bool _showPassword = false;

  Future<void> _copyValue(String value, String label) async {
    await _copySensitiveValue(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label已复制')));
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE8EAF1)),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.selectionMode ? widget.onSelect : widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectionMode)
                Checkbox(
                  value: widget.selected,
                  onChanged: (_) => widget.onSelect?.call(),
                ),
              IconButton(
                tooltip: _tx('移到回收站'),
                visualDensity: VisualDensity.compact,
                onPressed: widget.onMoveToTrash,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFF5267D8),
                ),
              ),
              _VaultIcon(bytes: entry.iconBytes, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.name.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          entry.name,
                          translate: false,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (entry.account.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '账号：${entry.account}',
                              style: const TextStyle(color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: _tx('复制账号'),
                            onPressed: () => _copyValue(entry.account, '账号'),
                            icon: const Icon(Icons.copy_outlined, size: 18),
                          ),
                        ],
                      ),
                    if (entry.password.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '密码：${_showPassword ? entry.password : '•' * entry.password.length}',
                              style: const TextStyle(color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: _tx(_showPassword ? '隐藏密码' : '显示密码'),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: _tx('复制密码'),
                            onPressed: () => _copyValue(entry.password, '密码'),
                            icon: const Icon(Icons.copy_outlined, size: 18),
                          ),
                        ],
                      ),
                    if (entry.gesturePattern.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.gesture,
                              size: 16,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '手势密码',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({
    super.key,
    required this.entry,
    this.onUpdated,
    this.onMoveToTrash,
    this.readOnly = false,
  });

  final VaultEntry entry;
  final ValueChanged<VaultEntry>? onUpdated;
  final ValueChanged<VaultEntry>? onMoveToTrash;
  final bool readOnly;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage>
    with _LocaleAware<EntryDetailPage> {
  late VaultEntry _entry;
  bool _showPassword = false;
  bool _showGesturePattern = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Future<void> _copyValue(String value, String label) async {
    await _copySensitiveValue(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label已复制')));
  }

  Future<void> _edit() async {
    if (widget.readOnly) return;
    final updated = await showDialog<VaultEntry>(
      context: context,
      builder: (context) => _EntryEditorDialog(initialEntry: _entry),
    );
    if (updated != null && mounted) {
      setState(() => _entry = updated);
      widget.onUpdated?.call(updated);
    }
  }

  Future<void> _moveToTrash() async {
    if (widget.readOnly) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('移到回收站？'),
        content: Text('之后可以在回收站中恢复，或彻底删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('移到回收站'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onMoveToTrash?.call(_entry);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _entry.name.isEmpty ? _tx('条目详情') : _entry.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, translate: false),
        actions: [
          const _LanguageButton(),
          if (!widget.readOnly) ...[
            IconButton(
              tooltip: _tx('编辑'),
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: _tx('移到回收站'),
              onPressed: _moveToTrash,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(child: _VaultIcon(bytes: _entry.iconBytes, size: 88)),
                  const SizedBox(height: 24),
                  if (_entry.name.isNotEmpty)
                    _DetailRow(label: '名称', value: _entry.name),
                  if (_entry.account.isNotEmpty)
                    _DetailRow(
                      label: '账号',
                      value: _entry.account,
                      onCopy: widget.readOnly
                          ? null
                          : () => _copyValue(_entry.account, '账号'),
                    ),
                  if (_entry.password.isNotEmpty)
                    _DetailRow(
                      label: '密码',
                      value: _showPassword
                          ? _entry.password
                          : '•' * _entry.password.length,
                      onCopy: widget.readOnly
                          ? null
                          : () => _copyValue(_entry.password, '密码'),
                      trailing: IconButton(
                        tooltip: _tx(_showPassword ? '隐藏密码' : '显示密码'),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  if (_entry.gesturePattern.isNotEmpty)
                    _DetailRow(
                      label: '手势密码',
                      value: '',
                      trailing: IconButton(
                        tooltip: _tx(_showGesturePattern ? '隐藏手势密码' : '显示手势密码'),
                        onPressed: () => setState(
                          () => _showGesturePattern = !_showGesturePattern,
                        ),
                        icon: Icon(
                          _showGesturePattern
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                  if (_showGesturePattern && _entry.gesturePattern.isNotEmpty)
                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: CustomPaint(
                          painter: _GesturePatternPainter(
                            points: _decodeGesturePattern(
                              _entry.gesturePattern,
                            ),
                            showPath: true,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    '密码库内容已加密保存在此设备上。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAF1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          if (value.isNotEmpty)
            Expanded(child: SelectableText(value))
          else
            const Spacer(),
          if (onCopy != null)
            IconButton(
              tooltip: _english.value ? 'Copy' : '复制',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

class TrashPage extends StatefulWidget {
  const TrashPage({
    super.key,
    required this.entries,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final List<VaultEntry> entries;
  final ValueChanged<VaultEntry> onRestore;
  final ValueChanged<VaultEntry> onDeleteForever;

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> with _LocaleAware<TrashPage> {
  late final List<VaultEntry> _items = List<VaultEntry>.of(widget.entries);
  final Set<int> _selectedIndices = {};
  bool _selectionMode = false;

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedIndices.clear();
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndices.length == _items.length) {
        _selectedIndices.clear();
      } else {
        _selectedIndices
          ..clear()
          ..addAll(List<int>.generate(_items.length, (index) => index));
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (!_selectedIndices.add(index)) _selectedIndices.remove(index);
    });
  }

  void _restore(VaultEntry entry) {
    widget.onRestore(entry);
    setState(() => _items.remove(entry));
  }

  Future<void> _deleteForever(VaultEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('彻底删除？'),
        content: Text('此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('彻底删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      widget.onDeleteForever(entry);
      setState(() => _items.remove(entry));
    }
  }

  void _restoreSelected() {
    if (_selectedIndices.isEmpty) return;
    final indexes = _selectedIndices.toList()..sort();
    final restoring = indexes.map((index) => _items[index]).toList();
    for (final entry in restoring) {
      widget.onRestore(entry);
    }
    for (final index in indexes.reversed) {
      _items.removeAt(index);
    }
    setState(() {
      _selectedIndices.clear();
      _selectionMode = false;
    });
  }

  Future<void> _deleteSelectedForever() async {
    if (_selectedIndices.isEmpty) return;
    final count = _selectedIndices.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('彻底删除？'),
        content: Text(
          _english.value
              ? 'Permanently delete $count selected items? This cannot be undone.'
              : '确定彻底删除选中的$count个条目吗？此操作无法撤销。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('彻底删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final indexes = _selectedIndices.toList()..sort();
    final deleting = indexes.map((index) => _items[index]).toList();
    for (final entry in deleting) {
      widget.onDeleteForever(entry);
    }
    for (final index in indexes.reversed) {
      _items.removeAt(index);
    }
    setState(() {
      _selectedIndices.clear();
      _selectionMode = false;
    });
  }

  void _openReadOnly(VaultEntry entry) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => EntryDetailPage(entry: entry, readOnly: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode ? '${_selectedIndices.length} 项已选' : '回收站'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectionMode,
              child: Text(_selectionMode ? '取消选择' : '选择'),
            ),
          const _LanguageButton(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      '回收站是空的',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = _items[index];
                      final selected = _selectedIndices.contains(index);
                      return Card(
                        margin: EdgeInsets.zero,
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF5267D8)
                                : const Color(0xFFE8EAF1),
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _selectionMode
                              ? () => _toggleSelection(index)
                              : () => _openReadOnly(entry),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                if (_selectionMode)
                                  Checkbox(
                                    value: selected,
                                    onChanged: (_) => _toggleSelection(index),
                                  ),
                                _VaultIcon(bytes: entry.iconBytes, size: 44),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.name.isEmpty
                                        ? _tx('未命名条目')
                                        : entry.name,
                                    translate: false,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (!_selectionMode) ...[
                                  IconButton(
                                    tooltip: _tx('恢复'),
                                    onPressed: () => _restore(entry),
                                    icon: const Icon(Icons.restore),
                                  ),
                                  IconButton(
                                    tooltip: _tx('彻底删除'),
                                    onPressed: () => _deleteForever(entry),
                                    icon: const Icon(
                                      Icons.delete_forever_outlined,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
      bottomNavigationBar: _selectionMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _toggleSelectAll,
                      icon: const Icon(Icons.select_all),
                      label: Text(
                        _selectedIndices.length == _items.length
                            ? '取消全选'
                            : '全选',
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _selectedIndices.isEmpty
                          ? null
                          : _restoreSelected,
                      icon: const Icon(Icons.restore),
                      label: Text('恢复'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _selectedIndices.isEmpty
                          ? null
                          : _deleteSelectedForever,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: Text('彻底删除'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _VaultIcon extends StatelessWidget {
  const _VaultIcon({this.bytes, required this.size});

  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFF0F1FF),
        alignment: Alignment.center,
        child: bytes == null
            ? const Icon(Icons.key_outlined, color: Color(0xFF5267D8))
            : Image.memory(
                bytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF0F1FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 34,
              color: Color(0xFF5267D8),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '密码库还是空的',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('点击“添加条目”开始体验', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text('添加条目'),
          ),
        ],
      ),
    );
  }
}







