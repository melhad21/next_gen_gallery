import 'package:equatable/equatable.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';

enum AlbumType { auto, custom, vault, trash }

class AlbumEntity extends Equatable {
  final String id;
  final String name;
  final String? coverPath;
  final List<MediaEntity> assets;
  final AlbumType type;
  final DateTime createdDate;
  final int assetCount;
  final String? aiCategory;

  const AlbumEntity({
    required this.id,
    required this.name,
    this.coverPath,
    this.assets = const [],
    required this.type,
    required this.createdDate,
    this.assetCount = 0,
    this.aiCategory,
  });

  AlbumEntity copyWith({
    String? id,
    String? name,
    String? coverPath,
    List<MediaEntity>? assets,
    AlbumType? type,
    DateTime? createdDate,
    int? assetCount,
    String? aiCategory,
  }) {
    return AlbumEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPath: coverPath ?? this.coverPath,
      assets: assets ?? this.assets,
      type: type ?? this.type,
      createdDate: createdDate ?? this.createdDate,
      assetCount: assetCount ?? this.assetCount,
      aiCategory: aiCategory ?? this.aiCategory,
    );
  }

  @override
  List<Object?> get props => [id, name, type];
}