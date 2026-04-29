import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';
import 'package:antigravity_gallery/domain/entities/album_entity.dart';
import 'package:antigravity_gallery/domain/repositories/media_repository.dart';
import 'package:antigravity_gallery/core/services/service_locator.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return sl<MediaRepository>();
});

final galleryStateProvider = StateNotifierProvider<GalleryStateNotifier, GalleryState>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return GalleryStateNotifier(repository);
});

final albumsProvider = FutureProvider<List<AlbumEntity>>((ref) async {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.getAllAlbums();
});

final selectedAlbumProvider = StateProvider<AlbumEntity?>((ref) => null);

final permissionProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.requestPermission();
});

class GalleryState {
  final List<MediaEntity> assets;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const GalleryState({
    this.assets = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  GalleryState copyWith({
    List<MediaEntity>? assets,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return GalleryState(
      assets: assets ?? this.assets,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class GalleryStateNotifier extends StateNotifier<GalleryState> {
  final MediaRepository _repository;
  static const int _pageSize = 100;

  GalleryStateNotifier(this._repository) : super(const GalleryState());

  Future<void> loadInitialMedia() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final assets = await _repository.getAllMedia(page: 0, pageSize: _pageSize);
      state = state.copyWith(
        assets: assets,
        isLoading: false,
        hasMore: assets.length >= _pageSize,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreMedia() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final newAssets = await _repository.getAllMedia(page: nextPage, pageSize: _pageSize);

      state = state.copyWith(
        assets: [...state.assets, ...newAssets],
        isLoading: false,
        hasMore: newAssets.length >= _pageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const GalleryState();
    await loadInitialMedia();
  }

  void addAsset(MediaEntity asset) {
    state = state.copyWith(assets: [asset, ...state.assets]);
  }

  void removeAsset(String assetId) {
    state = state.copyWith(
      assets: state.assets.where((a) => a.id != assetId).toList(),
    );
  }

  void updateAsset(MediaEntity asset) {
    final index = state.assets.indexWhere((a) => a.id == asset.id);
    if (index != -1) {
      final newAssets = [...state.assets];
      newAssets[index] = asset;
      state = state.copyWith(assets: newAssets);
    }
  }
}