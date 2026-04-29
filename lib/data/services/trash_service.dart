import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';
import 'package:antigravity_gallery/domain/entities/trash_item_entity.dart';

class TrashService {
  static const String _trashDataKey = 'trash_items';

  final _uuid = const Uuid();

  Future<String> get _trashDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final trashDir = Directory('${appDir.path}/${AppConstants.trashDirName}');
    if (!await trashDir.exists()) {
      await trashDir.create(recursive: true);
      await File('${trashDir.path}/${AppConstants.nomediaFile}').writeAsString('');
    }
    return trashDir.path;
  }

  Future<List<TrashItemEntity>> getTrashItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString(_trashDataKey);
    if (itemsJson == null) return [];

    final List<dynamic> itemsList = jsonDecode(itemsJson);
    final items = itemsList.map((item) => TrashItemEntity(
      id: item['id'],
      originalPath: item['originalPath'],
      trashPath: item['trashPath'],
      deletedDate: DateTime.parse(item['deletedDate']),
      expiryDate: DateTime.parse(item['expiryDate']),
      thumbnailPath: item['thumbnailPath'],
      isVideo: item['isVideo'],
      duration: item['duration'],
    )).toList();

    items.sort((a, b) => b.deletedDate.compareTo(a.deletedDate));
    return items;
  }

  Future<TrashItemEntity> moveToTrash(String sourcePath, {bool isVideo = false, int? duration}) async {
    final trashDir = await _trashDirectory;
    final fileName = '${_uuid.v4()}${_getExtension(sourcePath)}';
    final destPath = '$trashDir/$fileName';

    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    await sourceFile.delete();

    final expiryDate = DateTime.now().add(Duration(days: AppConstants.trashRetentionDays));

    final item = TrashItemEntity(
      id: _uuid.v4(),
      originalPath: sourcePath,
      trashPath: destPath,
      deletedDate: DateTime.now(),
      expiryDate: expiryDate,
      isVideo: isVideo,
      duration: duration,
    );

    await _saveTrashItem(item);
    return item;
  }

  Future<void> _saveTrashItem(TrashItemEntity item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getTrashItems();
    items.add(item);

    await _saveAllItems(items);
  }

  String _getExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    return '.$ext';
  }

  Future<void> restoreFromTrash(String itemId) async {
    final items = await getTrashItems();
    final item = items.firstWhere((i) => i.id == itemId);

    final trashFile = File(item.trashPath);
    if (await trashFile.exists()) {
      await trashFile.copy(item.originalPath);
      await trashFile.delete();
    }

    items.removeWhere((i) => i.id == itemId);
    await _saveAllItems(items);
  }

  Future<void> deleteFromTrash(String itemId) async {
    final items = await getTrashItems();
    final item = items.firstWhere((i) => i.id == itemId);

    final trashFile = File(item.trashPath);
    if (await trashFile.exists()) {
      await trashFile.delete();
    }

    items.removeWhere((i) => i.id == itemId);
    await _saveAllItems(items);
  }

  Future<void> _saveAllItems(List<TrashItemEntity> items) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(items.map((i) => {
      'id': i.id,
      'originalPath': i.originalPath,
      'trashPath': i.trashPath,
      'deletedDate': i.deletedDate.toIso8601String(),
      'expiryDate': i.expiryDate.toIso8601String(),
      'thumbnailPath': i.thumbnailPath,
      'isVideo': i.isVideo,
      'duration': i.duration,
    }).toList());
    await prefs.setString(_trashDataKey, itemsJson);
  }

  Future<void> emptyTrash() async {
    final items = await getTrashItems();

    for (final item in items) {
      final trashFile = File(item.trashPath);
      if (await trashFile.exists()) {
        await trashFile.delete();
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trashDataKey, '[]');
  }

  Future<void> cleanExpired() async {
    final items = await getTrashItems();
    final now = DateTime.now();

    final expiredItems = items.where((item) => item.expiryDate.isBefore(now)).toList();

    for (final item in expiredItems) {
      final trashFile = File(item.trashPath);
      if (await trashFile.exists()) {
        await trashFile.delete();
      }
    }

    items.removeWhere((item) => item.expiryDate.isBefore(now));
    await _saveAllItems(items);
  }

  Future<int> getTrashCount() async {
    final items = await getTrashItems();
    return items.length;
  }

  Future<File?> getThumbnail(String itemId) async {
    final items = await getTrashItems();
    final item = items.firstWhere((i) => i.id == itemId);

    final file = File(item.trashPath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }
}