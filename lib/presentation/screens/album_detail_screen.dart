import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:antigravity_gallery/domain/entities/album_entity.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';
import 'package:antigravity_gallery/data/services/media_service.dart';
import 'package:antigravity_gallery/presentation/providers/gallery_provider.dart';
import 'package:antigravity_gallery/presentation/screens/viewer_screen.dart';
import 'package:antigravity_gallery/presentation/widgets/media_thumbnail.dart';
import 'package:antigravity_gallery/core/services/service_locator.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final AlbumEntity album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  List<MediaEntity> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mediaService = sl<MediaService>();
      if (widget.album.id.startsWith('ai_')) {
      } else {
        final assets = await mediaService.getMediaByAlbum(widget.album.id);
        setState(() {
          _assets = assets;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? _buildEmptyState()
              : _buildGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No photos in this album',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        return MediaThumbnail(
          key: ValueKey(asset.id),
          asset: asset,
          isSelected: false,
          onTap: () => _openViewer(index),
          onLongPress: () {},
        );
      },
    );
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ViewerScreen(
          initialIndex: index,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}