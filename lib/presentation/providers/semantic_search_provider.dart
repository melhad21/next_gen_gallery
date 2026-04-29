import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/domain/entities/media_entity.dart';
import 'package:antigravity_gallery/domain/repositories/media_repository.dart';
import 'package:antigravity_gallery/data/services/ai_classification_service.dart';
import 'package:antigravity_gallery/core/services/service_locator.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return sl<MediaRepository>();
});

final semanticSearchServiceProvider = Provider<SemanticSearchService>((ref) {
  return sl<SemanticSearchService>();
});

final semanticSearchProvider = StateNotifierProvider<SemanticSearchNotifier, SemanticSearchState>((ref) {
  final service = ref.watch(semanticSearchServiceProvider);
  return SemanticSearchNotifier(service);
});

class SemanticSearchState {
  final List<MediaEntity> results;
  final String query;
  final bool isSearching;
  final List<String> recentSearches;

  const SemanticSearchState({
    this.results = const [],
    this.query = '',
    this.isSearching = false,
    this.recentSearches = const [],
  });

  SemanticSearchState copyWith({
    List<MediaEntity>? results,
    String? query,
    bool? isSearching,
    List<String>? recentSearches,
  }) {
    return SemanticSearchState(
      results: results ?? this.results,
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

class SemanticSearchNotifier extends StateNotifier<SemanticSearchState> {
  final SemanticSearchService _service;

  SemanticSearchNotifier(this._service) : super(const SemanticSearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(results: [], query: '', isSearching: false);
      return;
    }

    state = state.copyWith(query: query, isSearching: true);

    try {
      final results = await _service.search(query);
      
      final recent = [query, ...state.recentSearches.where((s) => s != query).take(4)];
      
      state = state.copyWith(
        results: results,
        isSearching: false,
        recentSearches: recent,
      );
    } catch (e) {
      state = state.copyWith(isSearching: false);
    }
  }

  void clearSearch() {
    state = state.copyWith(results: [], query: '');
  }
}

class SemanticSearchService {
  final AIClassificationService _aiService;

  SemanticSearchService(this._aiService);

  Future<List<MediaEntity>> search(String query) async {
    final normalizedQuery = query.toLowerCase();
    
    final categories = _mapQueryToCategories(normalizedQuery);
    
    if (categories.isEmpty) {
      return _searchByLabels(normalizedQuery);
    }

    final allResults = <MediaEntity>[];
    
    for (final category in categories) {
      final categoryResults = await _aiService.getMediaByCategory(category);
      allResults.addAll(categoryResults.map((c) => MediaEntity(
        id: c.mediaId,
        path: c.mediaId,
        type: MediaType.image,
        width: 0,
        height: 0,
        size: 0,
        createdDate: c.classifiedAt,
        modifiedDate: c.classifiedAt,
      )));
    }

    allResults.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return allResults;
  }

  List<String> _mapQueryToCategories(String query) {
    final categoryMappings = {
      'selfie': ['selfie', 'self-portrait', 'portrait', 'me', 'person'],
      'food': ['food', 'dish', 'meal', 'pizza', 'cake', 'cooking', 'restaurant'],
      'pet': ['pet', 'dog', 'cat', 'animal', 'puppy', 'kitten'],
      'document': ['document', 'receipt', 'text', 'paper', 'file', 'scan'],
      'landscape': ['landscape', 'nature', 'mountain', 'beach', 'sunset', 'sunrise', 'tree'],
      'screenshot': ['screenshot', 'screen', 'app'],
      'travel': ['travel', 'trip', 'vacation', 'airplane', 'hotel', 'city', 'building'],
      'art': ['art', 'painting', 'sculpture', 'museum'],
      'nature': ['flower', 'plant', 'bird', 'animal', 'wildlife'],
      'car': ['car', 'vehicle', 'motorcycle', 'bike'],
    };

    final matched = <String>[];
    for (final entry in categoryMappings.entries) {
      for (final keyword in entry.value) {
        if (query.contains(keyword)) {
          matched.add(entry.key);
          break;
        }
      }
    }

    return matched;
  }

  Future<List<MediaEntity>> _searchByLabels(String query) async {
    return [];
  }
}