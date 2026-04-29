import 'package:equatable/equatable.dart';

enum MediaType { image, video, unknown }

class MediaEntity extends Equatable {
  final String id;
  final String path;
  final String? thumbnailPath;
  final MediaType type;
  final int width;
  final int height;
  final int size;
  final DateTime createdDate;
  final DateTime modifiedDate;
  final String? mimeType;
  final int? duration;
  final String? albumId;

  const MediaEntity({
    required this.id,
    required this.path,
    this.thumbnailPath,
    required this.type,
    required this.width,
    required this.height,
    required this.size,
    required this.createdDate,
    required this.modifiedDate,
    this.mimeType,
    this.duration,
    this.albumId,
  });

  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;

  @override
  List<Object?> get props => [id, path, type];
}