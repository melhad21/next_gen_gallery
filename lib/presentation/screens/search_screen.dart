import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/presentation/providers/gallery_provider.dart';
import 'package:antigravity_gallery/presentation/screens/viewer_screen.dart';
import 'package:antigravity_gallery/presentation/widgets/media_thumbnail.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  final List<String> _recentSearches = [];
  final List<MapEntry<String, String>> _suggestions = [
    const MapEntry('red car', 'Travel'),
    const MapEntry('beach sunset', 'Landscapes'),
    const MapEntry('pizza', 'Food'),
    const MapEntry('dog', 'Pets'),
    const MapEntry('selfie', 'Selfies'),
    const MapEntry('screenshot', 'Screenshots'),
    const MapEntry('document', 'Documents'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final galleryState = ref.read(galleryStateProvider);

    final results = galleryState.assets.where((asset) {
      final title = asset.id.toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });

    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search photos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
              ),
              onSubmitted: _performSearch,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasSearched) {
      return _searchResults.isEmpty
          ? _buildNoResults()
          : _buildResults();
    }

    return _buildSuggestions();
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final asset = _searchResults[index];
        return MediaThumbnail(
          key: ValueKey(asset.id),
          asset: asset,
          isSelected: false,
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => ViewerScreen(
                  initialIndex: index,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          onLongPress: () {},
        );
      },
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _recentSearches.clear();
                  });
                },
                child: const Text('Clear'),
              ),
            ],
          ),
          ..._recentSearches.map((search) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
              )),
          const SizedBox(height: 16),
        ],
        Text(
          'Suggested Searches',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((suggestion) {
            return ActionChip(
              avatar: const Icon(Icons.search, size: 18),
              label: Text(suggestion.key),
              onPressed: () {
                _searchController.text = suggestion.key;
                _performSearch(suggestion.key);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}