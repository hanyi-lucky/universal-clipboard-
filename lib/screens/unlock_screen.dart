import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clipboard_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/local_storage.dart';
import '../services/encryption_service.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  final _encryption = EncryptionService();
  bool _isFirstTime = true;
  bool _initialized = false;
  bool _authSuccess = false;
  String? _error;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final auth = context.read<AuthProvider>();
      final storage = await LocalStorage.create();
      await auth.initialize(storage);
      await auth.signIn();

      final settings = context.read<SettingsProvider>();
      await settings.initialize(storage);

      if (!mounted) return;
      setState(() {
        _isFirstTime = storage.encryptionSalt == null;
        _initialized = true;
        _authSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _authSuccess = false;
        _error = '连接失败: $e';
      });
    }
  }

  Future<void> _unlock() async {
    if (!_authSuccess) return;

    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final storage = await LocalStorage.create();
      final auth = context.read<AuthProvider>();
      List<int> salt;

      final existingSalt = storage.encryptionSalt;
      if (existingSalt == null) {
        salt = _encryption.generateSalt().toList();
        final saltHex = salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        await storage.setEncryptionSalt(saltHex);
      } else {
        salt = [];
        for (int i = 0; i < existingSalt.length; i += 2) {
          salt.add(int.parse(existingSalt.substring(i, i + 2), radix: 16));
        }
      }

      final key = await _encryption.deriveKey(password, salt);
      final clipboardProvider = context.read<ClipboardProvider>();

      await clipboardProvider.initialize(
        storage: storage,
        cloudRepo: auth.cloudRepo,
        deviceId: auth.currentDevice.id,
        deviceName: auth.currentDevice.name,
        encryptionKey: key,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '解锁失败: $e';
      });
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                if (!_initialized)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('正在连接服务器...', style: TextStyle(color: Colors.grey)),
                    ],
                  )
                else if (!_authSuccess)
                  Column(
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        '无法连接服务器',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请检查网络连接后重试',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                          onPressed: () {
                            setState(() {
                              _initialized = false;
                              _error = null;
                            });
                            _init();
                          },
                        ),
                      ),
                    ],
                  )
                else ...[
                  Text(
                    _isFirstTime ? '设置主密码' : '解锁',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isFirstTime
                        ? '创建密码加密剪切板数据。请在所有设备上使用相同密码。'
                        : '输入主密码解锁。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '主密码',
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _unlock(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _unlock,
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isFirstTime ? '创建并开始' : '解锁'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
