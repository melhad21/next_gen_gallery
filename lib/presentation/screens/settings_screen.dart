import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/presentation/providers/settings_provider.dart';
import 'package:antigravity_gallery/presentation/providers/vault_provider.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            'Appearance',
            [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Use dark theme'),
                value: settings.isDarkMode,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setDarkMode(value);
                },
              ),
              ListTile(
                title: const Text('Grid Columns'),
                subtitle: Text('${settings.gridColumns} columns'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showGridColumnsPicker(context, ref, settings.gridColumns),
              ),
            ],
          ),
          _buildSection(
            context,
            'AI Features',
            [
              SwitchListTile(
                title: const Text('AI Classification'),
                subtitle: const Text('Automatically organize photos'),
                value: settings.aiEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setAiEnabled(value);
                },
              ),
              ListTile(
                title: const Text('Smart Albums'),
                subtitle: const Text('View AI-generated albums'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          _buildSection(
            context,
            'Security',
            [
              ListTile(
                title: const Text('Vault Settings'),
                subtitle: const Text('Manage hidden vault'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showVaultSettings(context, ref),
              ),
              SwitchListTile(
                title: const Text('Biometric Lock'),
                subtitle: const Text('Use fingerprint for vault'),
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
          _buildSection(
            context,
            'Storage',
            [
              ListTile(
                title: const Text('Clear Cache'),
                subtitle: const Text('Free up storage space'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearCacheDialog(context),
              ),
              ListTile(
                title: const Text('Trash'),
                subtitle: const Text('Manage deleted items'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          _buildSection(
            context,
            'About',
            [
              ListTile(
                title: const Text('Version'),
                subtitle: Text(AppConstants.appVersion),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  void _showGridColumnsPicker(BuildContext context, WidgetRef ref, int currentColumns) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Grid Columns',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...List.generate(5, (index) {
                final columns = index + 2;
                return ListTile(
                  title: Text('$columns columns'),
                  trailing: currentColumns == columns
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setGridColumns(columns);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showVaultSettings(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change PIN'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangePinDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_off),
                title: const Text('Reset Decoy Mode'),
                subtitle: const Text('Reset decoy vault settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Reset Vault', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Delete all hidden photos'),
                onTap: () {
                  Navigator.pop(context);
                  _showResetVaultDialog(context, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: const Text('Feature coming soon'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetVaultDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Vault'),
        content: const Text('Are you sure? This will delete all hidden photos permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached thumbnails and temporary files.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}