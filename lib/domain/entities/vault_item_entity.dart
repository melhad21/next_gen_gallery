import 'package:equatable/equatable.dart';

class VaultItemEntity extends Equatable {
  final String id;
  final String originalPath;
  final String vaultPath;
  final DateTime movedDate;
  final String? thumbnailPath;
  final bool isVideo;
  final String? originalAlbumId;

  const VaultItemEntity({
    required this.id,
    required this.originalPath,
    required this.vaultPath,
    required this.movedDate,
    this.thumbnailPath,
    required this.isVideo,
    this.originalAlbumId,
  });

  @override
  List<Object?> get props => [id, originalPath, vaultPath];
}