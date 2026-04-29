import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/presentation/providers/vault_provider.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _pinController = TextEditingController();
  bool _isSettingUp = false;
  bool _showSetupWizard = false;
  bool _isTrueVault = false;
  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _checkSetupStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkSetupStatus() async {
    final isSetup = await ref.read(vaultSetupProvider.future);
    if (!isSetup && mounted) {
      setState(() {
        _showSetupWizard = true;
        _isSettingUp = true;
      });
    }
  }

  void _onSecretTap() {
    final now = DateTime.now();

    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 500) {
      _secretTapCount++;
    } else {
      _secretTapCount = 1;
    }

    _lastTapTime = now;

    if (_secretTapCount >= 2) {
      setState(() {
        _isTrueVault = true;
      });
      _secretTapCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(vaultStateProvider);

    if (_showSetupWizard && _isSettingUp) {
      return _buildSetupWizard();
    }

    if (vaultState.isAuthenticated) {
      return _buildVaultContent();
    }

    return _buildLoginScreen();
  }

  Widget _buildSetupWizard() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Vault'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Create a PIN for your vault',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This PIN will be used for the TRUE hidden vault',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter PIN (4-6 digits)',
                prefixIcon: Icon(Icons.pin),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _setupVault,
                child: const Text('Set Up Vault'),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    'After setup, there will be a DECOY vault accessible via the normal PIN. The TRUE vault is accessed via a secret gesture.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupVault() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits')),
      );
      return;
    }

    final success = await ref.read(vaultStateProvider.notifier).setupVault(pin);
    if (success && mounted) {
      setState(() {
        _isSettingUp = false;
        _showSetupWizard = false;
      });
    }
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isTrueVault ? 'Authenticate' : 'Hidden Pictures'),
      ),
      body: GestureDetector(
        onDoubleTap: _onSecretTap,
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 500) {
            _onSecretTap();
          }
        },
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: _isTrueVault
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isTrueVault
                          ? 'Authenticate to access hidden vault'
                          : 'Enter PIN to access hidden pictures',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Enter PIN',
                      prefixIcon: const Icon(Icons.pin),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTrueVault ? _authenticateTrueVault : _authenticateDecoy,
                      child: const Text('Unlock'),
                    ),
                  ),
                  if (!_isTrueVault) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Hint: Double-tap and swipe down on the title bar for the TRUE vault',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _authenticateDecoy() async {
    final pin = _pinController.text;
    if (pin.isEmpty) return;

    await ref.read(vaultStateProvider.notifier).verifyDecoyPin(pin);

    setState(() {
      _pinController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Accessing decoy vault...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _authenticateTrueVault() async {
    final pin = _pinController.text;
    if (pin.isEmpty) return;

    final success = await ref.read(vaultStateProvider.notifier).verifyTruePin(pin);

    if (success) {
      setState(() {
        _pinController.clear();
        _isTrueVault = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication failed')),
      );
    }
  }

  Widget _buildVaultContent() {
    final vaultState = ref.watch(vaultStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(vaultState.isDecoyMode ? 'Hidden Pictures' : 'True Vault'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(vaultStateProvider.notifier).lockVault();
            ref.read(vaultStateProvider.notifier).exitDecoy();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock),
            onPressed: () {
              ref.read(vaultStateProvider.notifier).lockVault();
            },
          ),
        ],
      ),
      body: vaultState.isDecoyMode ? _buildDecoyContent() : _buildTrueVaultContent(vaultState),
    );
  }

  Widget _buildDecoyContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No hidden pictures',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'This is the decoy vault',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrueVaultContent(VaultState vaultState) {
    if (vaultState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Vault is empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Move photos here from the gallery',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: vaultState.items.length,
      itemBuilder: (context, index) {
        final item = vaultState.items[index];
        return GestureDetector(
          onLongPress: () => _showItemOptions(item.id),
          child: Container(
            color: Colors.grey[800],
            child: const Icon(Icons.lock, color: Colors.white54),
          ),
        );
      },
    );
  }

  void _showItemOptions(String itemId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore to Gallery'),
                onTap: () {
                  ref.read(vaultStateProvider.notifier).restoreFromVault(itemId);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                onTap: () {
                  ref.read(vaultStateProvider.notifier).deleteFromVault(itemId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}