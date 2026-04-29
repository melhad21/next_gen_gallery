import 'package:antigravity_gallery/data/services/vault_service.dart';
import 'package:antigravity_gallery/domain/entities/vault_item_entity.dart';
import 'package:antigravity_gallery/domain/repositories/vault_repository.dart';

class VaultRepositoryImpl implements VaultRepository {
  final VaultService _vaultService;

  VaultRepositoryImpl(this._vaultService);

  @override
  Future<bool> isVaultSetup() {
    return _vaultService.isVaultSetup();
  }

  @override
  Future<void> setupVault(String pin) {
    return _vaultService.setupVault(pin);
  }

  @override
  Future<bool> verifyDecoyPin(String pin) {
    return _vaultService.verifyDecoyPin(pin);
  }

  @override
  Future<bool> verifyTruePin(String pin) {
    return _vaultService.verifyTruePin(pin);
  }

  @override
  Future<bool> verifyBiometric() async {
    return true;
  }

  @override
  Future<List<VaultItemEntity>> getVaultItems() {
    return _vaultService.getVaultItems();
  }

  @override
  Future<VaultItemEntity> moveToVault(String mediaPath, {bool isVideo = false}) {
    return _vaultService.moveToVault(mediaPath, isVideo: isVideo);
  }

  @override
  Future<void> restoreFromVault(String itemId) {
    return _vaultService.restoreFromVault(itemId);
  }

  @override
  Future<void> deleteFromVault(String itemId) {
    return _vaultService.deleteFromVault(itemId);
  }

  @override
  Future<void> changePin(String oldPin, String newPin) {
    return _vaultService.changePin(oldPin, newPin);
  }

  @override
  Future<void> lockVault() {
    return _vaultService.lockVault();
  }

  @override
  Future<bool> isVaultLocked() {
    return _vaultService.isVaultLocked();
  }
}