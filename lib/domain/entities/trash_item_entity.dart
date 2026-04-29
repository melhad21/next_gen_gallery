import 'package:equatable/equatable.dart';

class TrashItemEntity extends Equatable {
  final String id;
  final String originalPath;
  final String trashPath;
  final DateTime deletedDate;
  final DateTime expiryDate;
  final String? thumbnailPath;
  final bool isVideo;
  final int? duration;

  const TrashItemEntity({
    required this.id,
    required this.originalPath,
    required this.trashPath,
    required this.deletedDate,
    required this.expiryDate,
    this.thumbnailPath,
    required this.isVideo,
    this.duration,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  int get daysRemaining => expiryDate.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [id, originalPath, deletedDate];
}