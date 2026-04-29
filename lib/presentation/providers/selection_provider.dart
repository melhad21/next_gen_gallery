import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';

final selectionProvider = StateNotifierProvider<SelectionNotifier, SelectionState>((ref) {
  return SelectionNotifier();
});

class SelectionState {
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const SelectionState({
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  SelectionState copyWith({
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return SelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get count => selectedIds.length;
  bool isSelected(String id) => selectedIds.contains(id);
  List<String> get selectedList => selectedIds.toList();
}

class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(const SelectionState());

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelectionMode: !state.isSelectionMode,
      selectedIds: state.isSelectionMode ? {} : state.selectedIds,
    );
  }

  void exitSelectionMode() {
    state = state.copyWith(
      isSelectionMode: false,
      selectedIds: {},
    );
  }

  void toggleSelection(String id) {
    final newSelected = Set<String>.from(state.selectedIds);
    if (newSelected.contains(id)) {
      newSelected.remove(id);
    } else {
      newSelected.add(id);
    }
    state = state.copyWith(selectedIds: newSelected);
  }

  void selectAll(List<MediaEntity> assets) {
    final allIds = assets.map((a) => a.id).toSet();
    state = state.copyWith(
      selectedIds: allIds,
      isSelectionMode: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }
}