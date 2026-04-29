import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_gallery/core/services/service_locator.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final themeProvider = StateProvider<bool>((ref) {
  return ref.watch(settingsProvider).isDarkMode;
});

class SettingsState {
  final bool isDarkMode;
  final int gridColumns;
  final bool aiEnabled;
  final bool vaultEnabled;

  const SettingsState({
    this.isDarkMode = true,
    this.gridColumns = AppConstants.defaultGridColumns,
    this.aiEnabled = true,
    this.vaultEnabled = false,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    int? gridColumns,
    bool? aiEnabled,
    bool? vaultEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      gridColumns: gridColumns ?? this.gridColumns,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      vaultEnabled: vaultEnabled ?? this.vaultEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = sl<SharedPreferences>();

    final isDarkMode = prefs.getBool(AppConstants.keyThemeMode) ?? true;
    final gridColumns = prefs.getInt(AppConstants.keyGridColumns) ?? AppConstants.defaultGridColumns;
    final aiEnabled = prefs.getBool(AppConstants.keyAIEnabled) ?? true;
    final vaultEnabled = prefs.getBool(AppConstants.keyVaultEnabled) ?? false;

    state = state.copyWith(
      isDarkMode: isDarkMode,
      gridColumns: gridColumns,
      aiEnabled: aiEnabled,
      vaultEnabled: vaultEnabled,
    );
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(AppConstants.keyThemeMode, isDarkMode);
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  Future<void> setGridColumns(int columns) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setInt(AppConstants.keyGridColumns, columns);
    state = state.copyWith(gridColumns: columns);
  }

  Future<void> setAiEnabled(bool enabled) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(AppConstants.keyAIEnabled, enabled);
    state = state.copyWith(aiEnabled: enabled);
  }

  Future<void> setVaultEnabled(bool enabled) async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(AppConstants.keyVaultEnabled, enabled);
    state = state.copyWith(vaultEnabled: enabled);
  }
}