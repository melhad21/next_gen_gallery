import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';
import 'package:antigravity_gallery/domain/entities/vault_item_entity.dart';

class VaultService {
  static const String _pinKey = 'vault_pin_hash';
  static const String _isSetupKey = 'vault_setup_complete';
  static const String _vaultDataKey = 'vault_items';
  static const String _isLockedKey = 'vault_is_locked';
  static const String _lastActivityKey = 'vault_last_activity';

  final _uuid = const Uuid();

  Future<String> get _vaultDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/${AppConstants.vaultDirName}');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
      await File('${vaultDir.path}/${AppConstants.nomediaFile}').writeAsString('');
    }
    return vaultDir.path;
  }

  Future<String> get _decoyDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final decoyDir = Directory('${appDir.path}/${AppConstants.decoyDirName}');
    if (!await decoyDir.exists()) {
      await decoyDir.create(recursive: true);
      await File('${decoyDir.path}/${AppConstants.decoyNomedia}').writeAsString('');
    }
    return decoyDir.path;
  }

  Future<bool> isVaultSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSetupKey) ?? false;
  }

  Future<void> setupVault(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = _hashPin(pin);
    await prefs.setString(_pinKey, pinHash);
    await prefs.setBool(_isSetupKey, true);
  }

  Future<bool> verifyDecoyPin(String pin) async {
    return true;
  }

  Future<bool> verifyTruePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_pinKey);
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'antigravity_salt');
    return sha256.convert(bytes).toString();
  }

  Future<List<VaultItemEntity>> getVaultItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(_vaultDataKey);
    if (itemsJson == null) return [];

    final List<dynamic> itemsList = jsonDecode(itemsJson);
    return itemsList.map((item) => VaultItemEntity(
      id: item['id'],
      originalPath: item['originalPath'],
      vaultPath: item['vaultPath'],
      movedDate: DateTime.parse(item['movedDate']),
      thumbnailPath: item['thumbnailPath'],
      isVideo: item['isVideo'],
      originalAlbumId: item['originalAlbumId'],
    )).toList();
  }

  Future<VaultItemEntity> moveToVault(String sourcePath, {bool isVideo = false}) async {
    final vaultDir = await _vaultDirectory;
    final fileName = '${_uuid.v4()}${_getExtension(sourcePath)}';
    final destPath = '$vaultDir/$fileName';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    await sourceFile.delete();

    final thumbnailPath = isVideo ? null : destPath;

    final item = VaultItemEntity(
      id: _uuid.v4(),
      originalPath: sourcePath,
      vaultPath: destPath,
      movedDate: DateTime.now(),
      thumbnailPath: thumbnailPath,
      isVideo: isVideo,
    );

    await _saveVaultItem(item);
    return item;
  }

  Future<void> _saveVaultItem(VaultItemEntity item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getVaultItems();
    items.add(item);

    final itemsJson = jsonEncode(items.map((i) => {
      'id': i.id,
      'originalPath': i.originalPath,
      'vaultPath': i.vaultPath,
      'movedDate': i.movedDate.toIso8601String(),
      'thumbnailPath': i.thumbnailPath,
      'isVideo': i.isVideo,
      'originalAlbumId': i.originalAlbumId,
    }).toList());

    await prefs.setString(_vaultDataKey, itemsJson);
  }

  String _getExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return '.$ext';
  }

  Future<void> restoreFromVault(String itemId) async {
    final items = await getVaultItems();
    final item = items.firstWhere((i) => i.id == itemId);

    final vaultFile = File(item.vaultPath);
    if (await vaultFile.exists()) {
      await vaultFile.copy(item.originalPath);
      await vaultFile.delete();
    }

    items.removeWhere((i) => i.id == itemId);
    await _saveAllItems(items);
  }

  Future<void> deleteFromVault(String itemId) async {
    final items = await getVaultItems();
    final item = items.firstWhere((i) => i.id == itemId);

    final vaultFile = File(item.vaultPath);
    if (await vaultFile.exists()) {
      await vaultFile.delete();
    }

    items.removeWhere((i) => i.id == itemId);
    await _saveAllItems(items);
  }

  Future<void> _saveAllItems(List<VaultItemEntity> items) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(items.map((i) => {
      'id': i.id,
      'originalPath': i.originalPath,
      'vaultPath': i.vaultPath,
      'movedDate': i.movedDate.toIso8601String(),
      'thumbnailPath': i.thumbnailPath,
      'isVideo': i.isVideo,
      'originalAlbumId': i.originalAlbumId,
    }).toList());
    await prefs.setString(_vaultDataKey, itemsJson);
  }

  Future<void> changePin(String oldPin, String newPin) async {
    final isValid = await verifyTruePin(oldPin);
    if (!isValid) throw Exception('Invalid old PIN');

    await setupVault(newPin);
  }

  Future<void> lockVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLockedKey, true);
    await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> isVaultLocked() async {
    final prefs = await SharedPreferences.getInstance();
    final isLocked = prefs.getBool(_isLockedKey) ?? true;

    if (isLocked) {
      final lastActivity = prefs.getInt(_lastActivityKey);
      if (lastActivity != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastActivity;
        if (elapsed < 30000) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> unlockVault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLockedKey, false);
  }

  Future<File?> getThumbnail(String itemId) async {
    final items = await getVaultItems();
    final item = items.firstWhere((i) => i.id == itemId);

    if (item.thumbnailPath != null) {
      final file = File(item.thumbnailPath!);
      if (await file.exists()) {
        return file;
      }
    }

    return null;
  }

  Future<Uint8List?> readVaultFile(String itemId) async {
    final items = await getVaultItems();
    final item = items.firstWhere((i) => i.id == itemId);

    final file = File(item.vaultPath);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<List<FileSystemEntity>> getDecoyFiles() async {
    final decoyDir = await _decoyDirectory;
    final directory = Directory(decoyDir);
    return directory.listSync();
  }
}