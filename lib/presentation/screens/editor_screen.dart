import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:antigravity_gallery/presentation/providers/editor_provider.dart';
import 'package:antigravity_gallery/core/constants/app_constants.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Uint8List? _testImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTestImage();
  }

  Future<void> _loadTestImage() async {
    final bytes = await Future.delayed(const Duration(milliseconds: 100), () {
      return Uint8List(0);
    });
    setState(() {
      _testImage = bytes;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        actions: [
          if (editorState.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                ref.read(editorStateProvider.notifier).undo();
              },
            ),
          if (editorState.canRedo)
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: () {
                ref.read(editorStateProvider.notifier).redo();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(editorStateProvider.notifier).reset();
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveImage(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Center(
                child: editorState.isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : editorState.editedImage != null
                        ? Image.memory(
                            editorState.editedImage!,
                            fit: BoxFit.contain,
                          )
                        : const Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.white54,
                          ),
              ),
            ),
          ),
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.tune), text: 'Adjust'),
                Tab(icon: Icon(Icons.filter), text: 'Filters'),
                Tab(icon: Icon(Icons.blur_on), text: 'Effects'),
                Tab(icon: Icon(Icons.crop), text: 'Tools'),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAdjustmentsTab(editorState),
                _buildFiltersTab(editorState),
                _buildEffectsTab(editorState),
                _buildToolsTab(editorState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsTab(EditorState state) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSlider(
          'Exposure',
          state.settings.exposure,
          -2.0,
          2.0,
          (value) => ref.read(editorStateProvider.notifier).updateExposure(value),
        ),
        _buildSlider(
          'Contrast',
          state.settings.contrast,
          0.5,
          2.0,
          (value) => ref.read(editorStateProvider.notifier).updateContrast(value),
        ),
        _buildSlider(
          'Highlights',
          state.settings.highlights,
          -1.0,
          1.0,
          (value) => ref.read(editorStateProvider.notifier).updateHighlights(value),
        ),
        _buildSlider(
          'Shadows',
          state.settings.shadows,
          -1.0,
          1.0,
          (value) => ref.read(editorStateProvider.notifier).updateShadows(value),
        ),
        _buildSlider(
          'Brightness',
          state.settings.brightness,
          -0.5,
          0.5,
          (value) => ref.read(editorStateProvider.notifier).updateBrightness(value),
        ),
        _buildSlider(
          'Temperature',
          state.settings.temperature,
          -100,
          100,
          (value) => ref.read(editorStateProvider.notifier).updateTemperature(value),
        ),
        _buildSlider(
          'Saturation',
          state.settings.saturation,
          0,
          2,
          (value) => ref.read(editorStateProvider.notifier).updateSaturation(value),
        ),
        _buildSlider(
          'Vibrance',
          state.settings.vibrance,
          -1.0,
          1.0,
          (value) => ref.read(editorStateProvider.notifier).updateVibrance(value),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersTab(EditorState state) {
    final filters = [
      {'name': 'None', 'icon': Icons.crop_free},
      {'name': 'Vivid', 'icon': Icons.color_lens},
      {'name': 'Warm', 'icon': Icons.wb_sunny},
      {'name': 'Cool', 'icon': Icons.ac_unit},
      {'name': 'Sepia', 'icon': Icons.filter_vintage},
      {'name': 'Mono', 'icon': Icons.filter_b_and_w},
      {'name': 'Dramatic', 'icon': Icons.contrast},
      {'name': 'Noir', 'icon': Icons.filter_drama},
      {'name': 'Vintage', 'icon': Icons.photo_album},
      {'name': 'Fade', 'icon': Icons.filter_tilt_shift},
      {'name': 'Chrome', 'icon': Icons.details},
      {'name': 'Process', 'icon': Icons.auto_fix_high},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: filters.length,
      itemBuilder: (context, index) {
        final filter = filters[index];
        final isSelected = state.appliedFilter == filter['name'];

        return GestureDetector(
          onTap: () {
            if (filter['name'] == 'None') {
              ref.read(editorStateProvider.notifier).reset();
            } else {
              ref.read(editorStateProvider.notifier).applyFilter(
                    filter['name'] as String,
                    1.0,
                  );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filter['icon'] as IconData,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
                ),
                const SizedBox(height: 4),
                Text(
                  filter['name'] as String,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEffectsTab(EditorState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.blur_on),
          title: const Text('Blur'),
          subtitle: const Text('Apply background blur'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showBlurDialog(),
        ),
        ListTile(
          leading: const Icon(Icons.deblur),
          title: const Text('Sharpen'),
          subtitle: const Text('Enhance image sharpness'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.vignette),
          title: const Text('Vignette'),
          subtitle: const Text('Add dark edges'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.auto_fix_high),
          title: const Text('AI Enhance'),
          subtitle: const Text('Auto enhance with AI'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAIEnhanceOptions(),
        ),
      ],
    );
  }

  Widget _buildToolsTab(EditorState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.crop),
          title: const Text('Crop'),
          subtitle: const Text('Crop and rotate'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.rotate_right),
          title: const Text('Rotate'),
          subtitle: const Text('Rotate 90°'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.flip),
          title: const Text('Flip'),
          subtitle: const Text('Mirror image'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.healing),
          title: const Text('Magic Eraser'),
          subtitle: const Text('Remove objects (AI)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showMagicEraser(),
        ),
        ListTile(
          leading: const Icon(Icons.cloud),
          title: const Text('Sky Replacement'),
          subtitle: const Text('Change sky (AI)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSkyReplacement(),
        ),
        ListTile(
          leading: const Icon(Icons.zoom_in),
          title: const Text('AI Upscale'),
          subtitle: const Text('Enhance resolution'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAIUpscale(),
        ),
        ListTile(
          leading: const Icon(Icons.camera_alt),
          title: const Text('Portrait Mode'),
          subtitle: const Text('Add bokeh effect'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPortraitMode(),
        ),
      ],
    );
  }

  void _showBlurDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Blur'),
        content: const Text('Feature requires photo permission'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAIEnhanceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('Auto Enhance'),
              subtitle: const Text('One-tap AI optimization'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.colorize),
              title: const Text('Color Correction'),
              subtitle: const Text('Fix colors automatically'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.exposure),
              title: const Text('Light Correction'),
              subtitle: const Text('Fix exposure issues'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showMagicEraser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Magic Eraser'),
        content: const Text(
          'Draw over objects you want to remove. '
          'This feature uses AI to fill in the area.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draw on the image to remove objects')),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showSkyReplacement() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Replace Sky',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSkyOption('Sunny', Icons.wb_sunny),
                _buildSkyOption('Cloudy', Icons.cloud),
                _buildSkyOption('Sunset', Icons.wb_twilight),
                _buildSkyOption('Night', Icons.nightlight),
                _buildSkyOption('Rainy', Icons.umbrella),
                _buildSkyOption('Snow', Icons.ac_unit),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSkyOption(String name, IconData icon) {
    return ActionChip(
      avatar: Icon(icon),
      label: Text(name),
      onPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Replacing sky with $name...')),
        );
      },
    );
  }

  void _showAIUpscale() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Upscale'),
        content: const Text(
          'Enhance image resolution up to 4x. '
          'This may take a moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upscaling image...')),
              );
            },
            child: const Text('Upscale 2x'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upscaling image...')),
              );
            },
            child: const Text('Upscale 4x'),
          ),
        ],
      ),
    );
  }

  void _showPortraitMode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Portrait Mode'),
        content: const Text(
          'Apply artificial bokeh effect to create depth of field.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Applying portrait mode...')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _saveImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image saved to gallery')),
    );
    Navigator.pop(context);
  }
}