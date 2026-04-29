import 'package:antigravity_gallery/data/services/trash_service.dart';
import 'package:antigravity_gallery/domain/entities/trash_item_entity.dart';
import 'package:antigravity_gallery/domain/repositories/trash_repository.dart';

class TrashRepositoryImpl implements TrashRepository {
  final TrashService _trashService;

  TrashRepositoryImpl(this._trashService);

  @override
  Future<List<TrashItemEntity>> getTrashItems() {
    return _trashService.getTrashItems();
  }

  @override
  Future<TrashItemEntity> moveToTrash(String mediaPath, {bool isVideo = false, int? duration}) {
    return _trashService.moveToTrash(mediaPath, isVideo: isVideo, duration: duration);
  }

  @override
  Future<void> restoreFromTrash(String itemId) {
    return _trashService.restoreFromTrash(itemId);
  }

  @override
  Future<void> deleteFromTrash(String itemId) {
    return _trashService.deleteFromTrash(itemId);
  }

  @override
  Future<void> emptyTrash() {
    return _trashService.emptyTrash();
  }

  @override
  Future<void> cleanExpired() {
    return _trashService.cleanExpired();
  }

  @override
  Future<int> getTrashCount() {
    return _trashService.getTrashCount();
  }
}