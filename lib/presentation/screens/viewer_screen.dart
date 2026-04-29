import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:antigravity_gallery/presentation/providers/gallery_provider.dart';
import 'package:antigravity_gallery/presentation/screens/editor_screen.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const ViewerScreen({
    super.key,
    required this.initialIndex,
  });

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isEditing = false;
  bool _showControls = true;
  double _playbackSpeed = 1.0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeVideo(String path) async {
    _videoController?.dispose();

    _videoController = VideoPlayerController.file(
      await AssetEntity.fromId(path) != null ? File(path) : File(path),
    );

    await _videoController!.initialize();
    await _videoController!.setLooping(true);

    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _openEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EditorScreen(),
      ),
    );
  }

  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Playback Speed',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...AppConstants.videoSpeeds.map((speed) {
                return ListTile(
                  title: Text('${speed}x'),
                  trailing: _playbackSpeed == speed
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    setState(() {
                      _playbackSpeed = speed;
                    });
                    _videoController?.setPlaybackSpeed(speed);
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

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryStateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: galleryState.assets.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final asset = galleryState.assets[index];

              if (asset.type == AssetType.video) {
                return _buildVideoViewer(asset);
              } else {
                return _buildImageViewer(asset);
              }
            },
          ),
          if (_showControls) _buildAppBar(galleryState),
          if (_showControls) _buildBottomBar(galleryState),
        ],
      ),
    );
  }

  Widget _buildImageViewer(dynamic asset) {
    return GestureDetector(
      onTap: _toggleControls,
      child: FutureBuilder<Uint8List?>(
        future: AssetEntity.fromId(asset.id)?.originBytes,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoViewer(dynamic asset) {
    return GestureDetector(
      onTap: _toggleControls,
      onDoubleTap: () {
        if (_videoController != null) {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        }
      },
      child: Center(
        child: _videoController == null || !_isVideoInitialized
            ? FutureBuilder<Uint8List?>(
                future: AssetEntity.fromId(asset.id)?.thumbnailDataWithSize(
                  const ThumbnailSize(300, 300),
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.memory(
                          snapshot.data!,
                          fit: BoxFit.contain,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill,
                            size: 64,
                            color: Colors.white,
                          ),
                          onPressed: () => _initializeVideo(asset.path),
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator(color: Colors.white);
                },
              )
            : AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
      ),
    );
  }

  Widget _buildAppBar(GalleryState galleryState) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${_currentIndex + 1} / ${galleryState.assets.length}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _openEditor,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(GalleryState galleryState) {
    final currentAsset = galleryState.assets[_currentIndex];
    final isVideo = currentAsset.type == AssetType.video;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomButton(
                  icon: Icons.info_outline,
                  label: 'Info',
                  onTap: () {},
                ),
                if (isVideo)
                  _buildBottomButton(
                    icon: Icons.speed,
                    label: '${_playbackSpeed}x',
                    onTap: _showSpeedSelector,
                  ),
                _buildBottomButton(
                  icon: isVideo ? Icons.video_settings : Icons.image,
                  label: isVideo ? 'Video' : 'Photo',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}