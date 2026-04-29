import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/presentation/providers/trash_provider.dart';
import 'package:antigravity_gallery/presentation/screens/viewer_screen.dart';
import 'package:antigravity_gallery/presentation/widgets/media_thumbnail.dart';
import 'package:intl/intl.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashState = ref.watch(trashStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (trashState.items.isNotEmpty)
            TextButton(
              onPressed: () => _showEmptyTrashDialog(context, ref),
              child: const Text('Empty'),
            ),
        ],
      ),
      body: trashState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : trashState.items.isEmpty
              ? _buildEmptyState(context)
              : _buildTrashList(context, ref, trashState),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Trash is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Deleted photos will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTrashList(BuildContext context, WidgetRef ref, TrashState trashState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Items are automatically deleted after 30 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: trashState.items.length,
            itemBuilder: (context, index) {
              final item = trashState.items[index];
              return Stack(
                children: [
                  MediaThumbnail(
                    key: ValueKey(item.id),
                    asset: _createMediaEntity(item),
                    isSelected: false,
                    onTap: () {
                      _showItemOptions(context, ref, item.id);
                    },
                    onLongPress: () {},
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.daysRemaining}d',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  dynamic _createMediaEntity(dynamic item) {
    return _TrashMediaProxy(item);
  }

  void _showItemOptions(BuildContext context, WidgetRef ref, String itemId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore'),
                onTap: () {
                  ref.read(trashStateProvider.notifier).restoreFromTrash(itemId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item restored')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete Now', style: TextStyle(color: Colors.red)),
                onTap: () {
                  ref.read(trashStateProvider.notifier).deleteFromTrash(itemId);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEmptyTrashDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash'),
        content: const Text(
          'Are you sure you want to permanently delete all items in trash? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(trashStateProvider.notifier).emptyTrash();
              Navigator.pop(context);
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TrashMediaProxy {
  final dynamic _item;
  _TrashMediaProxy(this._item);

  String get id => _item.id;
  String get path => _item.trashPath;
  bool get isVideo => _item.isVideo;
  int? get duration => _item.duration;
}