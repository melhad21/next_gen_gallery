import 'package:equatable/equatable.dart';

class AIClassificationEntity extends Equatable {
  final String mediaId;
  final String category;
  final List<String> labels;
  final double confidence;
  final DateTime classifiedAt;

  const AIClassificationEntity({
    required this.mediaId,
    required this.category,
    required this.labels,
    required this.confidence,
    required this.classifiedAt,
  });

  @override
  List<Object?> get props => [mediaId, category];
}