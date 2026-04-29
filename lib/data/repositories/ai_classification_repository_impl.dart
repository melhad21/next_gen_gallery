import 'package:antigravity_gallery/data/services/ai_classification_service.dart';
import 'package:antigravity_gallery/domain/entities/ai_classification_entity.dart';
import 'package:antigravity_gallery/domain/repositories/ai_classification_repository.dart';

class AIClassificationRepositoryImpl implements AIClassificationRepository {
  final AIClassificationService _classificationService;

  AIClassificationRepositoryImpl(this._classificationService);

  @override
  Future<AIClassificationEntity> classifyImage(String mediaPath) {
    return _classificationService.classifyImage(mediaPath);
  }

  @override
  Future<AIClassificationEntity?> classifyImageFromBytes(List<int> bytes) {
    return _classificationService.classifyImageFromBytes(bytes);
  }

  @override
  Future<Map<String, List<AIClassificationEntity>>> getClassifiedMedia() {
    return _classificationService.getClassifiedMedia();
  }

  @override
  Future<List<AIClassificationEntity>> getMediaByCategory(String category) {
    return _classificationService.getMediaByCategory(category);
  }

  @override
  Future<void> classifyAllMedia() async {}

  @override
  Stream<AIClassificationEntity> get classificationStream =>
      _classificationService.classificationStream;

  @override
  Future<bool> isClassificationComplete() {
    return _classificationService.isClassificationComplete();
  }

  @override
  Future<double> getClassificationProgress() {
    return _classificationService.getClassificationProgress();
  }
}