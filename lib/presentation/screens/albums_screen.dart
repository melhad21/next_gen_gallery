import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/presentation/providers/gallery_provider.dart';
import 'package:antigravity_gallery/domain/entities/album_entity.dart';
import 'package:antigravity_gallery/presentation/screens/album_detail_screen.dart';
import 'package:antigravity_gallery/data/services/ai_classification_service.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';

class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
      ),
      body: albumsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load albums'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refresh(albumsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (albums) => _buildAlbumsList(context, albums),
      ),
    );
  }

  Widget _buildAlbumsList(BuildContext context, List<AlbumEntity> albums) {
    final aiAlbums = _buildAIAlbums();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (aiAlbums.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Smart Albums',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...aiAlbums.map((album) => _buildAlbumTile(context, album)),
          const SizedBox(height: 24),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'All Albums',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...albums.map((album) => _buildAlbumTile(context, album)),
      ],
    );
  }

  List<AlbumEntity> _buildAIAlbums() {
    return AppConstants.aiCategories.map((category) {
      return AlbumEntity(
        id: 'ai_$category',
        name: category,
        type: AlbumType.auto,
        createdDate: DateTime.now(),
        assetCount: 0,
        aiCategory: category,
      );
    }).toList();
  }

  Widget _buildAlbumTile(BuildContext context, AlbumEntity album) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getAlbumIcon(album.name),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          album.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${album.assetCount} items',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlbumDetailScreen(album: album),
            ),
          );
        },
      ),
    );
  }

  IconData _getAlbumIcon(String name) {
    switch (name.toLowerCase()) {
      case 'selfies':
        return Icons.camera_alt;
      case 'food':
        return Icons.restaurant;
      case 'pets':
        return Icons.pets;
      case 'documents':
      case 'documents/receipts':
        return Icons.description;
      case 'landscapes':
        return Icons.landscape;
      case 'screenshots':
        return Icons.screenshot_monitor;
      case 'travel':
        return Icons.flight;
      case 'social':
        return Icons.people;
      case 'art':
        return Icons.palette;
      case 'nature':
        return Icons.forest;
      default:
        return Icons.photo_album;
    }
  }
}