import 'dart:async';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';
import 'package:antigravity_gallery/domain/entities/album_entity.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';

class MediaService {
  List<AssetEntity>? _cachedAssets;
  Map<String, AlbumEntity>? _cachedAlbums;

  Future<List<MediaEntity>> getAllMedia({int page = 0, int pageSize = 100}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );

    if (albums.isEmpty) return [];

    final allAlbum = albums.first;
    final assets = await allAlbum.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    return assets.map(_mapAssetToMediaEntity).toList();
  }

  Future<List<MediaEntity>> getMediaByAlbum(String albumId, {int page = 0, int pageSize = 100}) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    final album = albums.firstWhere(
      (a) => a.id == albumId,
      orElse: () => albums.first,
    );

    final assets = await album.getAssetListPaged(
      page: page,
      size: pageSize,
    );

    return assets.map(_mapAssetToMediaEntity).toList();
  }

  Future<List<AlbumEntity>> getAllAlbums() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
    );

    return Future.wait(albums.map((album) async {
      final count = await album.assetCountAsync;
      final assets = await album.getAssetListRange(start: 0, end: 1);
      final coverPath = assets.isNotEmpty ? await assets.first.thumbnailDataWithSize(
        const ThumbnailSize(AppConstants.thumbnailSize, AppConstants.thumbnailSize),
      ) : null;

      return AlbumEntity(
        id: album.id,
        name: album.name,
        coverPath: coverPath != null ? null : null,
        type: AlbumType.custom,
        createdDate: album.createDateTime,
        assetCount: count,
      );
    }));
  }

  Future<AlbumEntity?> getAlbumById(String id) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    try {
      final album = albums.firstWhere((a) => a.id == id);
      final count = await album.assetCountAsync;
      final assets = await album.getAssetListRange(start: 0, end: 1);
      String? coverPath;

      if (assets.isNotEmpty) {
        final thumb = await assets.first.thumbnailDataWithSize(
          const ThumbnailSize(AppConstants.thumbnailSize, AppConstants.thumbnailSize),
        );
        if (thumb != null) {
          coverPath = 'thumbnail';
        }
      }

      return AlbumEntity(
        id: album.id,
        name: album.name,
        coverPath: coverPath,
        type: AlbumType.custom,
        createdDate: album.createDateTime,
        assetCount: count,
      );
    } catch (e) {
      return null;
    }
  }

  Future<MediaEntity?> getMediaById(String id) async {
    final asset = await AssetEntity.fromId(id);
    if (asset == null) return null;
    return _mapAssetToMediaEntity(asset);
  }

  Future<List<MediaEntity>> searchMedia(String query) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    if (albums.isEmpty) return [];

    final allAlbum = albums.first;
    final assets = await allAlbum.getAssetList();

    return assets
        .where((asset) => asset.title?.toLowerCase().contains(query.toLowerCase()) ?? false)
        .map(_mapAssetToMediaEntity)
        .toList();
  }

  Future<Uint8List?> getThumbnail(String assetId, {int size = 300}) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;

    return asset.thumbnailDataWithSize(
      ThumbnailSize(size, size),
      quality: 90,
    );
  }

  Future<Uint8List?> getFullImage(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;

    return asset.originBytes;
  }

  Future<Uint8List?> getVideoThumbnail(String assetId) async {
    final asset = await AssetEntity.fromId(assetId);
    if (asset == null) return null;

    return asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
      quality: 90,
    );
  }

  MediaEntity _mapAssetToMediaEntity(AssetEntity asset) {
    return MediaEntity(
      id: asset.id,
      path: asset.path,
      type: asset.type == AssetType.video ? MediaType.video : MediaType.image,
      width: asset.width,
      height: asset.height,
      size: asset.size.width * asset.size.height,
      createdDate: asset.createDateTime,
      modifiedDate: asset.modifiedDateTime,
      mimeType: asset.mimeType,
      duration: asset.duration,
    );
  }

  Future<void> deleteAssets(List<String> assetIds) async {
    await PhotoManager.editor.deleteWithIds(assetIds);
  }

  Future<void> createAlbum(String name, List<String> assetIds) async {
    await PhotoManager.editor.createAlbum(name, assetIds: assetIds);
  }

  Future<void> addToAlbum(String albumId, List<String> assetIds) async {
    final album = await AssetPathEntity.fromId(albumId);
    if (album != null) {
      await PhotoManager.editor.addToAlbum(album, assetIds: assetIds);
    }
  }

  void dispose() {
    _cachedAssets = null;
    _cachedAlbums = null;
  }
}