import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/presentation/screens/gallery_screen.dart';
import 'package:antigravity_gallery/presentation/screens/albums_screen.dart';
import 'package:antigravity_gallery/presentation/screens/search_screen.dart';
import 'package:antigravity_gallery/presentation/screens/vault_screen.dart';
import 'package:antigravity_gallery/presentation/screens/trash_screen.dart';
import 'package:antigravity_gallery/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    GalleryScreen(),
    AlbumsScreen(),
    SearchScreen(),
    TrashScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_outlined),
            selectedIcon: Icon(Icons.collections),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.delete_outline),
            selectedIcon: Icon(Icons.delete),
            label: 'Trash',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openVault,
        icon: const Icon(Icons.lock_outline),
        label: const Text('Vault'),
      ),
    );
  }

  void _openVault() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VaultScreen(),
      ),
    );
  }
}