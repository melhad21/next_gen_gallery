import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:antigravity_gallery/presentation/providers/gallery_provider.dart';
import 'package:antigravity_gallery/presentation/providers/settings_provider.dart';
import 'package:antigravity_gallery/presentation/providers/selection_provider.dart';
import 'package:antigravity_gallery/presentation/screens/viewer_screen.dart';
import 'package:antigravity_gallery/presentation/widgets/media_thumbnail.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _scaleAnimationController;
  late Animation<double> _scaleAnimation;
  double _lastScale = 1.0;
  int _columnCount = 4;
  int _targetColumnCount = 4;
  bool _isAnimating = false;
  Ticker? _ticker;
  Duration _lastFrameTime = Duration.zero;
  double _velocity = 0;

  @override
  void initState() {
    super.initState();
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimationController.addListener(_onScaleAnimation);
    _scrollController.addListener(_onScroll);
    
    _ticker = createTicker(_onTick);
    _ticker?.start();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryStateProvider.notifier).loadInitialMedia();
    });
  }

  void _onTick(Duration elapsed) {
    final now = elapsed;
    if (_lastFrameTime.inMicroseconds > 0) {
      final delta = now - _lastFrameTime;
      if (_scrollController.hasClients) {
        _velocity = _scrollController.position.activity?.velocity ?? 0;
      }
    }
    _lastFrameTime = now;
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _scrollController.dispose();
    _ticker?.dispose();
    super.dispose();
  }

  void _onScaleAnimation() {
    if (_targetColumnCount != _columnCount) {
      setState(() {
        _columnCount = _targetColumnCount;
      });
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final delta = details.scale - _lastScale;
    _lastScale = details.scale;

    if (!_isAnimating) {
      if (delta > 0.15 && _columnCount > 2) {
        _setColumnCountInternal(_columnCount - 1);
      } else if (delta < -0.15 && _columnCount < 6) {
        _setColumnCountInternal(_columnCount + 1);
      }
    }
  }

  void _setColumnCountInternal(int newCount) {
    if (newCount != _targetColumnCount && newCount >= 2 && newCount <= 6) {
      _targetColumnCount = newCount;
      _scaleAnimationController.forward(from: 0);
    }
  }
  
  void _onScaleEnd(ScaleEndDetails details) {
    _lastScale = 1.0;
    _velocity = details.velocity.pixelsPerSecond.dy;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 500) {
      ref.read(galleryStateProvider.notifier).loadMoreMedia();
    }
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryStateProvider);
    final selectionState = ref.watch(selectionProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antigravity'),
        actions: [
          if (selectionState.isSelectionMode) ...[
            Text(
              '${selectionState.count}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                ref.read(selectionProvider.notifier).selectAll(galleryState.assets);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteSelected(),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref.read(selectionProvider.notifier).exitSelectionMode();
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: _showColumnSelector,
            ),
          ],
        ],
      ),
      body: _buildBody(galleryState, settings.gridColumns),
    );
  }

  Widget _buildBody(GalleryState galleryState, int settingsColumns) {
    if (galleryState.isLoading && galleryState.assets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (galleryState.error != null && galleryState.assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load media',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                ref.read(galleryStateProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (galleryState.assets.isEmpty) {
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
              'No photos yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Take some photos or import from gallery',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onScaleUpdate: (details) => _onScaleUpdate(details),
      onScaleEnd: _onScaleEnd,
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(galleryStateProvider.notifier).refresh();
        },
        child: MasonryGridView.count(
          controller: _scrollController,
          crossAxisCount: _columnCount,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          itemCount: galleryState.assets.length + (galleryState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= galleryState.assets.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final asset = galleryState.assets[index];
            final isSelected = ref.watch(selectionProvider).isSelected(asset.id);

            return MediaThumbnail(
              key: ValueKey(asset.id),
              asset: asset,
              isSelected: isSelected,
              onTap: () => _onThumbnailTap(asset, index),
              onLongPress: () => _onThumbnailLongPress(asset.id),
            );
          },
        ),
      ),
    );
  }

  void _onThumbnailTap(dynamic asset, int index) {
    final selectionState = ref.read(selectionProvider);

    if (selectionState.isSelectionMode) {
      ref.read(selectionProvider.notifier).toggleSelection(asset.id);
    } else {
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

  void _onThumbnailLongPress(String assetId) {
    ref.read(selectionProvider.notifier).toggleSelectionMode();
    ref.read(selectionProvider.notifier).toggleSelection(assetId);
  }

  void _showColumnSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.grid_2x2),
                title: const Text('2 Columns'),
                onTap: () => _setColumns(2),
              ),
              ListTile(
                leading: const Icon(Icons.grid_3x3),
                title: const Text('3 Columns'),
                onTap: () => _setColumns(3),
              ),
              ListTile(
                leading: const Icon(Icons.grid_4x4),
                title: const Text('4 Columns'),
                onTap: () => _setColumns(4),
              ),
              ListTile(
                leading: const Icon(Icons.grid_5x5),
                title: const Text('5 Columns'),
                onTap: () => _setColumns(5),
              ),
              ListTile(
                leading: const Icon(Icons.grid_6x6),
                title: const Text('6 Columns'),
                onTap: () => _setColumns(6),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setColumns(int columns) {
    setState(() {
      _columnCount = columns;
    });
    ref.read(settingsProvider.notifier).setGridColumns(columns);
    Navigator.pop(context);
  }

  void _deleteSelected() async {
    final selected = ref.read(selectionProvider).selectedList;
    if (selected.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to delete ${selected.length} items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in selected) {
        await PhotoManager.editor.deleteWithIds([id]);
      }
      ref.read(selectionProvider.notifier).exitSelectionMode();
      ref.read(galleryStateProvider.notifier).refresh();
    }
  }
}