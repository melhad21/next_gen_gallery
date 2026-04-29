import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';
import 'package:antigravity_gallery/presentation/providers/settings_provider.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String videoPath;
  final String? title;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    this.title,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullScreen = false;
  bool _isLocked = false;
  bool _isBuffering = false;
  double _currentSpeed = 1.0;
  int _selectedSpeedIndex = 4;
  Timer? _hideControlsTimer;
  Timer? _progressSaveTimer;
  Duration _lastPosition = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeOut,
    );
    _controlsAnimationController.forward();
    _startHideControlsTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersableSticky);
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
    
    try {
      await _controller.initialize();
      _controller.addListener(_videoListener);
      
      setState(() {
        _isInitialized = true;
        _totalDuration = _controller.value.duration;
      });
      
      _controller.play();
    } catch (e) {
      final fileController = VideoPlayerController.file(widget as dynamic);
      await fileController.initialize();
      _controller.addListener(_videoListener);
      
      setState(() {
        _isInitialized = true;
        _totalDuration = _controller.value.duration;
      });
      
      _controller.play();
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    setState(() {
      _currentPosition = _controller.value.position;
      _isBuffering = _controller.value.isBuffering;
    });

    if (_controller.value.position - _lastPosition > const Duration(seconds: 5)) {
      _lastPosition = _controller.value.position;
      ref.read(settingsProvider.notifier).setLastVideoPosition(
        _controller.value.position.inSeconds,
      );
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (_showControls && !_isLocked) {
        setState(() {
          _showControls = false;
        });
        _controlsAnimationController.reverse();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _controlsAnimationController.forward();
      _startHideControlsTimer();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _onTap() {
    if (_isLocked) return;
    _toggleControls();
  }

  void _setSpeed(double speed) {
    _controller.setPlaybackSpeed(speed);
    setState(() {
      _currentSpeed = speed;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _calculateProgress() {
    if (_totalDuration.inMilliseconds == 0) return 0;
    return _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
  }

  void _seekTo(double progress) {
    final position = Duration(
      milliseconds: (progress * _totalDuration.inMilliseconds).toInt(),
    );
    _controller.seekTo(position);
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _skipForward() {
    final newPosition = _controller.value.position + const Duration(seconds: 10);
    if (newPosition < _totalDuration) {
      _controller.seekTo(newPosition);
    }
  }

  void _skipBackward() {
    final newPosition = _controller.value.position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      _controller.seekTo(newPosition);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _showControls = false;
        _controlsAnimationController.reverse();
      }
    });
  }

  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Playback Speed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: AppConstants.videoSpeeds.asMap().entries.map((entry) {
                final speed = entry.value;
                final isSelected = _selectedSpeedIndex == entry.key;
                
                return ChoiceChip(
                  label: Text('${speed}x'),
                  selected: isSelected,
                  onSelected: (selected) {
                    _setSpeed(speed);
                    setState(() {
                      _selectedSpeedIndex = entry.key;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressSaveTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _controlsAnimationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _onTap,
        child: Stack(
          children: [
            _buildVideo(),
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _buildControls() {
    return FadeTransition(
      opacity: _controlsAnimation,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0, 0.2, 0.8, 1],
                ),
              ),
            ),
          ),
          _buildTopBar(),
          _buildCenterControls(),
          _buildBottomControls(),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  widget.title ?? 'Video',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open,
                  color: Colors.white,
                ),
                onPressed: _toggleLock,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white, size: 36),
            onPressed: _skipBackward,
          ),
          const SizedBox(width: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
              onPressed: _togglePlayPause,
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white, size: 36),
            onPressed: _skipForward,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    _formatDuration(_currentPosition),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSpeedSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_currentSpeed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDuration(_totalDuration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleFullScreen,
                    child: Icon(
                      _isFullScreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _calculateProgress(),
                      onChanged: _seekTo,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 3,
      child: LinearProgressIndicator(
        value: _calculateProgress(),
        backgroundColor: Colors.white.withOpacity(0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}