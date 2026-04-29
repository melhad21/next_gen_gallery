import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/domain/entities/vault_item_entity.dart';
import 'package:antigravity_gallery/domain/repositories/vault_repository.dart';
import 'package:antigravity_gallery/core/services/service_locator.dart';

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return sl<VaultRepository>();
});

final vaultStateProvider = StateNotifierProvider<VaultStateNotifier, VaultState>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return VaultStateNotifier(repository);
});

final vaultSetupProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(vaultRepositoryProvider);
  return repository.isVaultSetup();
});

class VaultState {
  final bool isDecoyMode;
  final bool isAuthenticated;
  final bool isLocked;
  final List<VaultItemEntity> items;
  final bool isLoading;
  final String? error;

  const VaultState({
    this.isDecoyMode = false,
    this.isAuthenticated = false,
    this.isLocked = true,
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  VaultState copyWith({
    bool? isDecoyMode,
    bool? isAuthenticated,
    bool? isLocked,
    List<VaultItemEntity>? items,
    bool? isLoading,
    String? error,
  }) {
    return VaultState(
      isDecoyMode: isDecoyMode ?? this.isDecoyMode,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLocked: isLocked ?? this.isLocked,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class VaultStateNotifier extends StateNotifier<VaultState> {
  final VaultRepository _repository;

  VaultStateNotifier(this._repository) : super(const VaultState()) {
    _init();
  }

  Future<void> _init() async {
    final isSetup = await _repository.isVaultSetup();
    final isLocked = await _repository.isVaultLocked();

    state = state.copyWith(
      isLocked: isSetup ? isLocked : true,
    );
  }

  Future<bool> setupVault(String pin) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.setupVault(pin);
      state = state.copyWith(
        isLoading: false,
        isLocked: false,
        isAuthenticated: true,
        isDecoyMode: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> verifyDecoy(String pin) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isValid = await _repository.verifyDecoyPin(pin);
      if (isValid) {
        final items = await _repository.getVaultItems();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isDecoyMode: true,
          items: [],
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> verifyTruePin(String pin) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isValid = await _repository.verifyTruePin(pin);
      if (isValid) {
        final biometricOk = await _repository.verifyBiometric();
        if (biometricOk) {
          final items = await _repository.getVaultItems();
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            isDecoyMode: false,
            isLocked: false,
            items: items,
          );
          return true;
        }
      }
      state = state.copyWith(isLoading: false, error: 'Authentication failed');
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> moveToVault(String mediaPath, {bool isVideo = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.moveToVault(mediaPath, isVideo: isVideo);
      final items = await _repository.getVaultItems();
      state = state.copyWith(
        isLoading: false,
        items: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> restoreFromVault(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.restoreFromVault(itemId);
      final items = await _repository.getVaultItems();
      state = state.copyWith(
        isLoading: false,
        items: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteFromVault(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.deleteFromVault(itemId);
      final items = await _repository.getVaultItems();
      state = state.copyWith(
        isLoading: false,
        items: items,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> lockVault() async {
    await _repository.lockVault();
    state = state.copyWith(
      isLocked: true,
      isAuthenticated: false,
    );
  }

  void exitDecoy() {
    state = state.copyWith(
      isAuthenticated: false,
      isDecoyMode: false,
    );
  }
}