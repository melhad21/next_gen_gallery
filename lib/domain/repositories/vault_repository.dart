import 'package:antigravity_gallery/domain/entities/vault_item_entity.dart';

abstract class VaultRepository {
  Future<bool> isVaultSetup();
  Future<void> setupVault(String pin);
  Future<bool> verifyDecoyPin(String pin);
  Future<bool> verifyTruePin(String pin);
  Future<bool> verifyBiometric();
  Future<List<VaultItemEntity>> getVaultItems();
  Future<VaultItemEntity> moveToVault(String mediaPath, {bool isVideo});
  Future<void> restoreFromVault(String itemId);
  Future<void> deleteFromVault(String itemId);
  Future<void> changePin(String oldPin, String newPin);
  Future<void> lockVault();
  Future<bool> isVaultLocked();
}