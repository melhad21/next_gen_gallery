import 'package:antigravity_gallery/domain/entities/media_entity.dart';
import 'package:antigravity_gallery/domain/entities/album_entity.dart';

abstract class MediaRepository {
  Future<List<MediaEntity>> getAllMedia({int page = 0, int pageSize = 100});
  Future<List<MediaEntity>> getMediaByAlbum(String albumId);
  Future<List<AlbumEntity>> getAllAlbums();
  Future<AlbumEntity> getAlbumById(String id);
  Future<MediaEntity?> getMediaById(String id);
  Future<List<MediaEntity>> searchMedia(String query);
  Future<void> deleteMedia(List<String> mediaIds);
  Future<void> addMediaToAlbum(String mediaId, String albumId);
  Future<void> removeMediaFromAlbum(String mediaId, String albumId);
  Future<bool> requestPermission();
  Stream<PermissionState> get permissionStream;
}

enum PermissionState { granted, denied, limited }