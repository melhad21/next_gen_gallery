import 'dart:async';
import 'package:antigravity_gallery/data/services/media_service.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';
import 'package:antigravity_gallery/domain/entities/album_entity.dart';
import 'package:antigravity_gallery/domain/repositories/media_repository.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaService _mediaService;
  final _permissionController = StreamController<PermissionState>.broadcast();

  MediaRepositoryImpl(this._mediaService);

  @override
  Stream<PermissionState> get permissionStream => _permissionController.stream;

  void dispose() {
    _permissionController.close();
  }

  @override
  Future<List<MediaEntity>> getAllMedia({int page = 0, int pageSize = 100}) {
    return _mediaService.getAllMedia(page: page, pageSize: pageSize);
  }

  @override
  Future<List<MediaEntity>> getMediaByAlbum(String albumId) {
    return _mediaService.getMediaByAlbum(albumId);
  }

  @override
  Future<List<AlbumEntity>> getAllAlbums() {
    return _mediaService.getAllAlbums();
  }

  @override
  Future<AlbumEntity?> getAlbumById(String id) {
    return _mediaService.getAlbumById(id);
  }

  @override
  Future<MediaEntity?> getMediaById(String id) {
    return _mediaService.getMediaById(id);
  }

  @override
  Future<List<MediaEntity>> searchMedia(String query) {
    return _mediaService.searchMedia(query);
  }

  @override
  Future<void> deleteMedia(List<String> mediaIds) {
    return _mediaService.deleteAssets(mediaIds);
  }

  @override
  Future<void> addMediaToAlbum(String mediaId, String albumId) {
    return _mediaService.addToAlbum(albumId, [mediaId]);
  }

  @override
  Future<void> removeMediaFromAlbum(String mediaId, String albumId) {
    return _mediaService.removeFromAlbum(albumId, [mediaId]);
  }

  @override
  Future<bool> requestPermission() {
    return _mediaService.requestPermission();
  }
}