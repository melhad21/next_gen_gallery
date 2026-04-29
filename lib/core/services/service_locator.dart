import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:antigravity_gallery/data/repositories/media_repository_impl.dart';
import 'package:antigravity_gallery/data/repositories/vault_repository_impl.dart';
import 'package:antigravity_gallery/data/repositories/trash_repository_impl.dart';
import 'package:antigravity_gallery/data/repositories/ai_classification_repository_impl.dart';
import 'package:antigravity_gallery/domain/repositories/media_repository.dart';
import 'package:antigravity_gallery/domain/repositories/vault_repository.dart';
import 'package:antigravity_gallery/domain/repositories/trash_repository.dart';
import 'package:antigravity_gallery/domain/repositories/ai_classification_repository.dart';
import 'package:antigravity_gallery/data/services/media_service.dart';
import 'package:antigravity_gallery/data/services/vault_service.dart';
import 'package:antigravity_gallery/data/services/trash_service.dart';
import 'package:antigravity_gallery/data/services/ai_classification_service.dart';
import 'package:antigravity_gallery/data/services/permission_service.dart';
import 'package:antigravity_gallery/data/services/image_processing_service.dart';
import 'package:antigravity_gallery/presentation/providers/semantic_search_provider.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);

    sl.registerLazySingleton<PermissionService>(() => PermissionService());
    sl.registerLazySingleton<MediaService>(() => MediaService());
    sl.registerLazySingleton<VaultService>(() => VaultService());
    sl.registerLazySingleton<TrashService>(() => TrashService());
    sl.registerLazySingleton<AIClassificationService>(() => AIClassificationService());
    sl.registerLazySingleton<ImageProcessingService>(() => ImageProcessingService());
    sl.registerLazySingleton<SemanticSearchService>(
      () => SemanticSearchService(sl<AIClassificationService>()),
    );

    sl.registerLazySingleton<MediaRepository>(
      () => MediaRepositoryImpl(sl<MediaService>()),
    );
    sl.registerLazySingleton<VaultRepository>(
      () => VaultRepositoryImpl(sl<VaultService>()),
    );
    sl.registerLazySingleton<TrashRepository>(
      () => TrashRepositoryImpl(sl<TrashService>()),
    );
    sl.registerLazySingleton<AIClassificationRepository>(
      () => AIClassificationRepositoryImpl(sl<AIClassificationService>()),
    );
  }
}