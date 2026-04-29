import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:photo_manager/photo_manager.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class DeclutterService {
  final _progressController = StreamController<DeclutterProgress>.broadcast();
  
  Stream<DeclutterProgress> get progressStream => _progressController.stream;

  Future<DeclutterResult> analyzeAllMedia() async {
    final result = DeclutterResult();
    
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      return result;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );
    
    if (albums.isEmpty) return result;
    
    final allAlbum = albums.first;
    final totalCount = await allAlbum.assetCountAsync;
    final assets = await allAlbum.getAssetListRange(start: 0, end: math.min(totalCount, 500));
    
    _progressController.add(DeclutterProgress(
      status: 'Analyzing photos...',
      progress: 0,
      total: totalCount,
    ));
    
    final duplicates = <DuplicateGroup>[];
    final blurred = <BlurredPhoto>[];
    final bursts = <BurstGroup>[];
    final screenshots = <AssetEntity>[];
    
    final processedHashes = <String, List<AssetEntity>>{};
    final burstGroups = <int, List<AssetEntity>>{};
    
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      
      _progressController.add(DeclutterProgress(
        status: 'Analyzing ${i + 1} of ${assets.length}...',
        progress: i + 1,
        total: assets.length,
      ));
      
      if (asset.type == AssetType.image) {
        if (asset.title?.toLowerCase().contains('screenshot') ?? false) {
          screenshots.add(asset);
        }
        
        try {
          final thumb = await asset.thumbnailDataWithSize(
            const ThumbnailSize(200, 200),
            quality: 50,
          );
          
          if (thumb != null) {
            final hash = _generate perceptualHash(thumb);
            
            processedHashes.putIfAbsent(hash, () => []);
            processedHashes[hash]!.add(asset);
            
            final blurScore = await _calculateBlurScore(thumb);
            if (blurScore < 50) {
              blurred.add(BlurredPhoto(
                asset: asset,
                blurScore: blurScore,
              ));
            }
          }
        } catch (e) {
          continue;
        }
        
        if (asset.createDateTime.year == DateTime.now().year &&
            asset.createDateTime.month == DateTime.now().month) {
          final key = '${asset.createDateTime.day}_${asset.createDateTime.hour}_${asset.createDateTime.minute}';
          burstGroups.putIfAbsent(key.hashCode, () => []);
          burstGroups[key.hashCode]!.add(asset);
        }
      }
    }
    
    for (final entry in processedHashes.entries) {
      if (entry.value.length > 1) {
        duplicates.add(DuplicateGroup(assets: entry.value));
      }
    }
    
    for (final entry in burstGroups.entries) {
      if (entry.value.length >= 3) {
        final sortedAssets = entry.value..sort((a, b) {
          final aSize = (a.width ?? 0) * (a.height ?? 0);
          final bSize = (b.width ?? 0) * (b.height ?? 0);
          return bSize.compareTo(aSize);
        });
        bursts.add(BurstGroup(assets: sortedAssets));
      }
    }
    
    result.duplicates = duplicates;
    result.blurredPhotos = blurred;
    result.bursts = bursts;
    result.screenshots = screenshots;
    
    await _saveResults(result);
    
    _progressController.add(DeclutterProgress(
      status: 'Complete!',
      progress: assets.length,
      total: assets.length,
    ));
    
    return result;
  }
  
  String _generate perceptualHash(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return '';
    
    final resized = img.copyResize(image, width: 8, height: 8);
    
    final pixels = <int>[];
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final pixel = resized.getPixel(x, y);
        final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toInt();
        pixels.add(gray);
      }
    }
    
    final avg = pixels.reduce((a, b) => a + b) / pixels.length;
    
    final hash = StringBuffer();
    for (final p in pixels) {
      hash.write(p > avg ? '1' : '0');
    }
    
    return hash.toString();
  }
  
  Future<double> _calculateBlurScore(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return 100;
    
    final grayscale = img.grayscale(image);
    
    final laplacian = img.sobel(grayscale);
    
    double sum = 0;
    for (int y = 0; y < laplacian.height; y++) {
      for (int x = 0; x < laplacian.width; x++) {
        final pixel = laplacian.getPixel(x, y);
        sum += pixel.r.toDouble();
      }
    }
    
    return sum / (laplacian.width * laplacian.height);
  }
  
  AssetEntity? getBestFromBurst(List<AssetEntity> assets) {
    if (assets.isEmpty) return null;
    
    AssetEntity? best;
    double bestScore = 0;
    
    for (final asset in assets) {
      final score = ((asset.width ?? 0) * (asset.height ?? 0)).toDouble();
      if (score > bestScore) {
        bestScore = score;
        best = asset;
      }
    }
    
    return best;
  }
  
  Future<void> _saveResults(DeclutterResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_declutter_duplicates', result.duplicates.length);
    await prefs.setInt('last_declutter_blurred', result.blurredPhotos.length);
    await prefs.setInt('last_declutter_bursts', result.bursts.length);
    await prefs.setInt('last_declutter_screenshots', result.screenshots.length);
    await prefs.setInt('last_declutter_time', DateTime.now().millisecondsSinceEpoch);
  }
  
  Future<DateTime?> getLastAnalysisTime() async {
    final prefs = await SharedPreferences.getInstance();
    final time = prefs.getInt('last_declutter_time');
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }
  
  void dispose() {
    _progressController.close();
  }
}

class DeclutterProgress {
  final String status;
  final int progress;
  final int total;
  
  DeclutterProgress({
    required this.status,
    required this.progress,
    required this.total,
  });
  
  double get percentage => total > 0 ? progress / total : 0;
}

class DeclutterResult {
  List<DuplicateGroup> duplicates = [];
  List<BlurredPhoto> blurredPhotos = [];
  List<BurstGroup> bursts = [];
  List<AssetEntity> screenshots = [];
  
  int get totalIssues =>
      duplicates.fold(0, (sum, g) => sum + g.assets.length - 1) +
      blurredPhotos.length +
      bursts.fold(0, (sum, g) => sum + g.assets.length - 1) +
      screenshots.length;
  
  bool get hasIssues => totalIssues > 0;
}

class DuplicateGroup {
  final List<AssetEntity> assets;
  final AssetEntity? recommended;
  
  DuplicateGroup({required this.assets}): recommended = _findRecommended(assets);
  
  static AssetEntity? _findRecommended(List<AssetEntity> assets) {
    if (assets.isEmpty) return null;
    
    AssetEntity? best;
    double bestScore = 0;
    
    for (final asset in assets) {
      final size = ((asset.width ?? 0) * (asset.height ?? 0)).toDouble();
      if (size > bestScore) {
        bestScore = size;
        best = asset;
      }
    }
    
    return best;
  }
}

class BlurredPhoto {
  final AssetEntity asset;
  final double blurScore;
  
  BlurredPhoto({
    required this.asset,
    required this.blurScore,
  });
}

class BurstGroup {
  final List<AssetEntity> assets;
  final AssetEntity? recommended;
  
  BurstGroup({required this.assets}): recommended = _findRecommended(assets);
  
  static AssetEntity? _findRecommended(List<AssetEntity> assets) {
    if (assets.isEmpty) return null;
    
    AssetEntity? best;
    double bestScore = 0;
    
    for (final asset in assets) {
      final size = ((asset.width ?? 0) * (asset.height ?? 0)).toDouble();
      if (size > bestScore) {
        bestScore = size;
        best = asset;
      }
    }
    
    return best;
  }
}