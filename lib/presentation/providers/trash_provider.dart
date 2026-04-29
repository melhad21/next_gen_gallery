import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/domain/entities/trash_item_entity.dart';
import 'package:antigravity_gallery/domain/repositories/trash_repository.dart';
import 'package:antigravity_gallery/core/services/service_locator.dart';

final trashRepositoryProvider = Provider<TrashRepository>((ref) {
  return sl<TrashRepository>();
});

final trashStateProvider = StateNotifierProvider<TrashStateNotifier, TrashState>((ref) {
  final repository = ref.watch(trashRepositoryProvider);
  return TrashStateNotifier(repository);
});

final trashCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(trashRepositoryProvider);
  return repository.getTrashCount();
});

class TrashState {
  final List<TrashItemEntity> items;
  final bool isLoading;
  final String? error;

  const TrashState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  TrashState copyWith({
    List<TrashItemEntity>? items,
    bool? isLoading,
    String? error,
  }) {
    return TrashState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TrashStateNotifier extends StateNotifier<TrashState> {
  final TrashRepository _repository;

  TrashStateNotifier(this._repository) : super(const TrashState()) {
    loadTrash();
  }

  Future<void> loadTrash() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.cleanExpired();
      final items = await _repository.getTrashItems();
      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> moveToTrash(String mediaPath, {bool isVideo = false, int? duration}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.moveToTrash(mediaPath, isVideo: isVideo, duration: duration);
      await loadTrash();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> restoreFromTrash(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.restoreFromTrash(itemId);
      await loadTrash();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteFromTrash(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.deleteFromTrash(itemId);
      await loadTrash();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> emptyTrash() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.emptyTrash();
      state = state.copyWith(
        items: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}