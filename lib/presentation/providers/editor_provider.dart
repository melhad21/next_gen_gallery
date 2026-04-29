import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/data/services/image_processing_service.dart';
import 'package:antigravity_gallery/core/services/service_locator.dart';

final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return sl<ImageProcessingService>();
});

final editorStateProvider = StateNotifierProvider<EditorStateNotifier, EditorState>((ref) {
  final imageService = ref.watch(imageProcessingServiceProvider);
  return EditorStateNotifier(imageService);
});

class EditorState {
  final Uint8List? originalImage;
  final Uint8List? editedImage;
  final bool isProcessing;
  final String? error;
  final EditorSettings settings;
  final List<EditorAction> actionHistory;
  final int historyIndex;
  final String? appliedFilter;
  final double filterIntensity;

  const EditorState({
    this.originalImage,
    this.editedImage,
    this.isProcessing = false,
    this.error,
    this.settings = const EditorSettings(),
    this.actionHistory = const [],
    this.historyIndex = -1,
    this.appliedFilter,
    this.filterIntensity = 1.0,
  });

  EditorState copyWith({
    Uint8List? originalImage,
    Uint8List? editedImage,
    bool? isProcessing,
    String? error,
    EditorSettings? settings,
    List<EditorAction>? actionHistory,
    int? historyIndex,
    String? appliedFilter,
    double? filterIntensity,
  }) {
    return EditorState(
      originalImage: originalImage ?? this.originalImage,
      editedImage: editedImage ?? this.editedImage,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      settings: settings ?? this.settings,
      actionHistory: actionHistory ?? this.actionHistory,
      historyIndex: historyIndex ?? this.historyIndex,
      appliedFilter: appliedFilter,
      filterIntensity: filterIntensity ?? this.filterIntensity,
    );
  }

  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < actionHistory.length - 1;
}

class EditorSettings {
  final double exposure;
  final double contrast;
  final double highlights;
  final double shadows;
  final double whites;
  final double blacks;
  final double temperature;
  final double tint;
  final double saturation;
  final double vibrance;
  final double brightness;

  const EditorSettings({
    this.exposure = 0,
    this.contrast = 1,
    this.highlights = 0,
    this.shadows = 0,
    this.whites = 0,
    this.blacks = 0,
    this.temperature = 0,
    this.tint = 0,
    this.saturation = 1,
    this.vibrance = 0,
    this.brightness = 0,
  });

  EditorSettings copyWith({
    double? exposure,
    double? contrast,
    double? highlights,
    double? shadows,
    double? whites,
    double? blacks,
    double? temperature,
    double? tint,
    double? saturation,
    double? vibrance,
    double? brightness,
  }) {
    return EditorSettings(
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      whites: whites ?? this.whites,
      blacks: blacks ?? this.blacks,
      temperature: temperature ?? this.temperature,
      tint: tint ?? this.tint,
      saturation: saturation ?? this.saturation,
      vibrance: vibrance ?? this.vibrance,
      brightness: brightness ?? this.brightness,
    );
  }
}

class EditorAction {
  final String name;
  final Map<String, dynamic> params;
  final DateTime timestamp;

  EditorAction({
    required this.name,
    required this.params,
    required this.timestamp,
  });
}

class EditorStateNotifier extends StateNotifier<EditorState> {
  final ImageProcessingService _imageService;

  EditorStateNotifier(this._imageService) : super(const EditorState());

  void setImage(Uint8List imageBytes) {
    state = state.copyWith(
      originalImage: imageBytes,
      editedImage: imageBytes,
      actionHistory: [],
      historyIndex: -1,
      settings: const EditorSettings(),
    );
  }

  Future<void> updateExposure(double value) async {
    await _applyAdjustment('exposure', value, (s) => s.copyWith(exposure: value));
  }

  Future<void> updateContrast(double value) async {
    await _applyAdjustment('contrast', value, (s) => s.copyWith(contrast: value));
  }

  Future<void> updateHighlights(double value) async {
    await _applyAdjustment('highlights', value, (s) => s.copyWith(highlights: value));
  }

  Future<void> updateShadows(double value) async {
    await _applyAdjustment('shadows', value, (s) => s.copyWith(shadows: value));
  }

  Future<void> updateTemperature(double value) async {
    await _applyAdjustment('temperature', value, (s) => s.copyWith(temperature: value));
  }

  Future<void> updateTint(double value) async {
    await _applyAdjustment('tint', value, (s) => s.copyWith(tint: value));
  }

  Future<void> updateSaturation(double value) async {
    await _applyAdjustment('saturation', value, (s) => s.copyWith(saturation: value));
  }

  Future<void> updateVibrance(double value) async {
    await _applyAdjustment('vibrance', value, (s) => s.copyWith(vibrance: value));
  }

  Future<void> updateBrightness(double value) async {
    await _applyAdjustment('brightness', value, (s) => s.copyWith(brightness: value));
  }

  Future<void> updateWhites(double value) async {
    await _applyAdjustment('whites', value, (s) => s.copyWith(whites: value));
  }

  Future<void> updateBlacks(double value) async {
    await _applyAdjustment('blacks', value, (s) => s.copyWith(blacks: value));
  }

  Future<void> _applyAdjustment(
    String name,
    double value,
    EditorSettings Function(EditorSettings) updateSettings,
  ) async {
    if (state.originalImage == null) return;

    state = state.copyWith(isProcessing: true);

    try {
      final newSettings = updateSettings(state.settings);
      final result = await _imageService.applyAdjustments(
        state.originalImage!,
        exposure: newSettings.exposure,
        contrast: newSettings.contrast,
        highlights: newSettings.highlights,
        shadows: newSettings.shadows,
        whites: newSettings.whites,
        blacks: newSettings.blacks,
        temperature: newSettings.temperature,
        tint: newSettings.tint,
        saturation: newSettings.saturation,
        vibrance: newSettings.vibrance,
        brightness: newSettings.brightness,
      );

      final action = EditorAction(
        name: name,
        params: {'value': value},
        timestamp: DateTime.now(),
      );

      final newHistory = state.actionHistory.sublist(0, state.historyIndex + 1);
      newHistory.add(action);

      state = state.copyWith(
        editedImage: result,
        settings: newSettings,
        isProcessing: false,
        actionHistory: newHistory,
        historyIndex: newHistory.length - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> applyFilter(String filterName, double intensity) async {
    if (state.editedImage == null) return;

    state = state.copyWith(isProcessing: true);

    try {
      final result = await _imageService.applyFilter(
        state.editedImage!,
        filterName,
        intensity,
      );

      final action = EditorAction(
        name: 'filter_$filterName',
        params: {'intensity': intensity},
        timestamp: DateTime.now(),
      );

      final newHistory = state.actionHistory.sublist(0, state.historyIndex + 1);
      newHistory.add(action);

      state = state.copyWith(
        editedImage: result,
        isProcessing: false,
        appliedFilter: filterName,
        filterIntensity: intensity,
        actionHistory: newHistory,
        historyIndex: newHistory.length - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> applyBlur(double radius) async {
    if (state.editedImage == null) return;

    state = state.copyWith(isProcessing: true);

    try {
      final result = await _imageService.applyBlur(state.editedImage!, radius.toInt());
      state = state.copyWith(
        editedImage: result,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> undo() async {
    if (!state.canUndo || state.originalImage == null) return;

    state = state.copyWith(isProcessing: true);

    try {
      var currentImage = state.originalImage!;

      for (int i = 0; i < state.historyIndex; i++) {
        final action = state.actionHistory[i];
        if (action.name == 'filter') {
          continue;
        }
      }

      state = state.copyWith(
        editedImage: currentImage,
        isProcessing: false,
        historyIndex: state.historyIndex - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> redo() async {
    if (!state.canRedo) return;

    state = state.copyWith(isProcessing: true);

    try {
      var currentImage = state.editedImage ?? state.originalImage!;

      state = state.copyWith(
        editedImage: currentImage,
        isProcessing: false,
        historyIndex: state.historyIndex + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = state.copyWith(
      editedImage: state.originalImage,
      settings: const EditorSettings(),
      actionHistory: [],
      historyIndex: -1,
      appliedFilter: null,
      filterIntensity: 1.0,
    );
  }

  Uint8List? getCurrentImage() {
    return state.editedImage ?? state.originalImage;
  }
}