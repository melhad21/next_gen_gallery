import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';

class MediaThumbnail extends StatefulWidget {
  final dynamic asset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MediaThumbnail({
    super.key,
    required this.asset,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<MediaThumbnail> createState() => _MediaThumbnailState();
}

class _MediaThumbnailState extends State<MediaThumbnail> {
  Uint8List? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(MediaThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final asset = await AssetEntity.fromId(widget.asset.id);
      if (asset != null) {
        final thumbnail = await asset.thumbnailDataWithSize(
          const ThumbnailSize(300, 300),
          quality: 85,
        );
        if (mounted) {
          setState(() {
            _thumbnail = thumbnail;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.asset.type == AssetType.video;
    final duration = widget.asset.duration;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Theme.of(context).extension<GalleryThemeExtension>()?.thumbnailPlaceholderColor,
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _thumbnail != null
                    ? Image.memory(
                        _thumbnail!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
          ),
          if (isVideo)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 14,
                    ),
                    if (duration != null)
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (widget.isSelected)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).extension<GalleryThemeExtension>()?.selectionOverlayColor,
                border: Border.all(
                  color: Theme.of(context).extension<GalleryThemeExtension>()?.selectedBorderColor ?? Colors.purple,
                  width: 3,
                ),
              ),
              child: const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}