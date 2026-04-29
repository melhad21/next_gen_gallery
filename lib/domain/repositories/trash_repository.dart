import 'package:antigravity_gallery/domain/entities/trash_item_entity.dart';

abstract class TrashRepository {
  Future<List<TrashItemEntity>> getTrashItems();
  Future<TrashItemEntity> moveToTrash(String mediaPath, {bool isVideo, int? duration});
  Future<void> restoreFromTrash(String itemId);
  Future<void> deleteFromTrash(String itemId);
  Future<void> emptyTrash();
  Future<void> cleanExpired();
  Future<int> getTrashCount();
}