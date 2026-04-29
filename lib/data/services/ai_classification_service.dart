import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';
import 'package:antigravity_gallery/domain/entities/ai_classification_entity.dart';

class AIClassificationService {
  ImageLabeler? _imageLabeler;
  final _classificationController = StreamController<AIClassificationEntity>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  bool _isInitialized = false;
  Isolate? _classificationIsolate;
  SendPort? _ isolateSendPort;
  ReceivePort? _isolateReceivePort;

  Stream<AIClassificationEntity> get classificationStream => _classificationController.stream;
  Stream<double> get progressStream => _progressController.stream;

  Future<void> init() async {
    if (_isInitialized) return;

    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    _imageLabeler = ImageLabeler(options: options);
    _isInitialized = true;
    await _startClassificationIsolate();
  }

  Future<void> _startClassificationIsolate() async {
    _isolateReceivePort = ReceivePort();
    _classificationIsolate = await Isolate.spawn(
      _isolateEntryPoint,
      _isolateReceivePort!.sendPort,
    );
    _isolateReceivePort!.listen(_handleIsolateMessage);
  }

  static void _isolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);
    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final result = await _processInIsolate(message);
        mainSendPort.send(result);
      }
    });
  }

  static Future<Map<String, dynamic>> _processInIsolate(Map<String, dynamic> params) async {
    return {'status': 'processed'};
  }

  void _handleIsolateMessage(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
    }
  }

  Future<AIClassificationEntity> classifyImage(String mediaPath) async {
    if (!_isInitialized) await init();

    final inputImage = InputImage.fromFilePath(mediaPath);
    final labels = await _imageLabeler!.processImage(inputImage);

    final category = _mapLabelsToCategory(labels.map((l) => l.label).toList());
    final confidence = labels.isNotEmpty
        ? labels.map((l) => l.confidence).reduce((a, b) => a > b ? a : b)
        : 0.0;

    final classification = AIClassificationEntity(
      mediaId: mediaPath,
      category: category,
      labels: labels.map((l) => l.label).toList(),
      confidence: confidence,
      classifiedAt: DateTime.now(),
    );

    _classificationController.add(classification);
    await _saveClassification(classification);

    return classification;
  }

  Future<AIClassificationEntity?> classifyImageFromThumbnail(
    Uint8List thumbnailBytes,
    int width,
    int height,
  ) async {
    if (!_isInitialized) await init();

    try {
      final inputImage = InputImage.fromBytes(
        bytes: thumbnailBytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: ImageRotation.rotation0,
          format: InputImageFormat.jpeg,
        ),
      );

      final labels = await _imageLabeler!.processImage(inputImage);

      final category = _mapLabelsToCategory(labels.map((l) => l.label).toList());
      final confidence = labels.isNotEmpty
          ? labels.map((l) => l.confidence).reduce((a, b) => a > b ? a : b)
          : 0.0;

      return AIClassificationEntity(
        mediaId: '',
        category: category,
        labels: labels.map((l) => l.label).toList(),
        confidence: confidence,
        classifiedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> classifyMediaBatch(
    List<String> mediaPaths,
    Function(AIClassificationEntity) onEach,
    Function(double) onProgress,
  ) async {
    if (!_isInitialized) await init();

    final total = mediaPaths.length;
    for (int i = 0; i < total; i++) {
      try {
        final classification = await classifyImage(mediaPaths[i]);
        onEach(classification);
        onProgress((i + 1) / total);
        _progressController.add((i + 1) / total);
      } catch (e) {
        continue;
      }
    }
  }

  String _mapLabelsToCategory(List<String> labels) {
    for (final label in labels) {
      final lower = label.toLowerCase();
      if (AppConstants.labelToCategory.containsKey(lower)) {
        return AppConstants.labelToCategory[lower]!;
      }

      for (final entry in AppConstants.labelToCategory.entries) {
        if (lower.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    return 'Other';
  }

  Future<void> _saveClassification(AIClassificationEntity classification) async {
    final prefs = await SharedPreferences.getInstance();
    final classificationsJson = prefs.getString('ai_classifications') ?? '{}';

    try {
      final classifications = _parseClassifications(classificationsJson);
      classifications[classification.mediaId] = classification;

      final newJson = _encodeClassifications(classifications);
      await prefs.setString('ai_classifications', newJson);
    } catch (e) {
      await prefs.setString('ai_classifications', '{}');
    }
  }

  Map<String, AIClassificationEntity> _parseClassifications(String json) {
    return {};
  }

  String _encodeClassifications(Map<String, AIClassificationEntity> classifications) {
    return '{}';
  }

  Future<Map<String, List<AIClassificationEntity>>> getClassifiedMedia() async {
    final prefs = await SharedPreferences.getInstance();
    final classificationsJson = prefs.getString('ai_classifications') ?? '{}';

    final classifications = _parseClassifications(classificationsJson);
    final grouped = <String, List<AIClassificationEntity>>{};

    for (final classification in classifications.values) {
      grouped.putIfAbsent(classification.category, () => []);
      grouped[classification.category]!.add(classification);
    }

    return grouped;
  }

  Future<List<AIClassificationEntity>> getMediaByCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final classificationsJson = prefs.getString('ai_classifications') ?? '{}';

    final classifications = _parseClassifications(classificationsJson);
    return classifications.values
        .where((c) => c.category == category)
        .toList();
  }

  Future<bool> isClassificationComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ai_classification_complete') ?? false;
  }

  Future<double> getClassificationProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('ai_classification_progress') ?? 0.0;
  }

  Future<void> setClassificationProgress(double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ai_classification_progress', progress);

    if (progress >= 1.0) {
      await prefs.setBool('ai_classification_complete', true);
    }
  }

  void dispose() {
    _imageLabeler?.close();
    _classificationController.close();
    _progressController.close();
    _classificationIsolate?.kill(priority: Isolate.immediate);
    _isolateReceivePort?.close();
  }
}