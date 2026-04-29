import 'package:antigravity_gallery/domain/entities/ai_classification_entity.dart';

abstract class AIClassificationRepository {
  Future<AIClassificationEntity> classifyImage(String mediaPath);
  Future<AIClassificationEntity?> classifyImageFromBytes(List<int> bytes);
  Future<Map<String, List<AIClassificationEntity>>> getClassifiedMedia();
  Future<List<AIClassificationEntity>> getMediaByCategory(String category);
  Future<void> classifyAllMedia();
  Stream<AIClassificationEntity> get classificationStream;
  Future<bool> isClassificationComplete();
  Future<double> getClassificationProgress();
}