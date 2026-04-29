import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

class ImageProcessingService {
  Future<Uint8List> applyAdjustments(
    Uint8List imageBytes, {
    double exposure = 0,
    double contrast = 1,
    double highlights = 0,
    double shadows = 0,
    double whites = 0,
    double blacks = 0,
    double temperature = 0,
    double tint = 0,
    double saturation = 1,
    double vibrance = 0,
    double brightness = 0,
  }) async {
    return await Isolate.run(() => _processAdjustments(
      imageBytes,
      exposure: exposure,
      contrast: contrast,
      highlights: highlights,
      shadows: shadows,
      temperature: temperature,
      saturation: saturation,
      vibrance: vibrance,
      brightness: brightness,
    ));
  }

  static Uint8List _processAdjustments(
    Uint8List data, {
    double exposure = 0,
    double contrast = 1,
    double highlights = 0,
    double shadows = 0,
    double temperature = 0,
    double saturation = 1,
    double vibrance = 0,
    double brightness = 0,
  }) {
    final image = img.decodeImage(data);
    if (image == null) return data;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        double r = pixel.r.toDouble();
        double g = pixel.g.toDouble();
        double b = pixel.b.toDouble();

        r = r * math.pow(2, exposure);
        g = g * math.pow(2, exposure);
        b = b * math.pow(2, exposure);
        r = ((r - 128) * contrast + 128).clamp(0, 255);
        g = ((g - 128) * contrast + 128).clamp(0, 255);
        b = ((b - 128) * contrast + 128).clamp(0, 255);
        r += brightness * 255;
        g += brightness * 255;
        b += brightness * 255;
        if (temperature != 0) {
          r += temperature * 0.5;
          b -= temperature * 0.5;
        }
        final avg = (r + g + b) / 3;
        final gray = avg / 255;
        if (highlights > 0 && gray > 0.5) {
          r += highlights * (gray - 0.5) * 100;
          g += highlights * (gray - 0.5) * 100;
          b += highlights * (gray - 0.5) * 100;
        }
        if (shadows > 0 && gray < 0.5) {
          r -= shadows * (0.5 - gray) * 100;
          g -= shadows * (0.5 - gray) * 100;
          b -= shadows * (0.5 - gray) * 100;
        }
        final satGray = 0.299 * r + 0.587 * g + 0.114 * b;
        r = satGray + saturation * (r - satGray);
        g = satGray + saturation * (g - satGray);
        b = satGray + saturation * (b - satGray);
        if (vibrance != 0) {
          final maxC = math.max(r, math.max(g, b));
          final amount = (1 - maxC / 255).clamp(0, 1);
          r += vibrance * amount * (r - satGray);
          g += vibrance * amount * (g - satGray);
          b += vibrance * amount * (b - satGray);
        }
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);
        image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), pixel.a.toInt());
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  Future<Uint8List> applyFilter(Uint8List imageBytes, String filterName, double intensity) async {
    return await Isolate.run(() => _applyColorFilter(imageBytes, filterName, intensity));
  }

  static Uint8List _applyColorFilter(Uint8List data, String filterName, double intensity) {
    final image = img.decodeImage(data);
    if (image == null) return data;

    final filters = _getFilterMatrix(filterName);
    if (filters == null) return data;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        double r = pixel.r.toDouble();
        double g = pixel.g.toDouble();
        double b = pixel.b.toDouble();
        final newR = (filters[0] * r + filters[1] * g + filters[2] * b).clamp(0, 255);
        final newG = (filters[3] * r + filters[4] * g + filters[5] * b).clamp(0, 255);
        final newB = (filters[6] * r + filters[7] * g + filters[8] * b).clamp(0, 255);
        r = r + (newR - r) * intensity;
        g = g + (newG - g) * intensity;
        b = b + (newB - b) * intensity;
        image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), pixel.a.toInt());
      }
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  static List<double>? _getFilterMatrix(String filterName) {
    switch (filterName.toLowerCase()) {
      case 'vivid': return [1.2, 0, 0, 0, 1.2, 0, 0, 0, 1.2];
      case 'warm': return [1.2, 0.1, 0, 0.1, 1.1, 0, 0, 0.1, 0.9];
      case 'cool': return [0.9, 0, 0.1, 0, 1.0, 0.1, 0.1, 0, 1.2];
      case 'sepia': return [0.393, 0.769, 0.189, 0.349, 0.686, 0.168, 0.272, 0.534, 0.131];
      case 'mono': return [0.299, 0.587, 0.114, 0.299, 0.587, 0.114, 0.299, 0.587, 0.114];
      case 'dramatic': return [1.5, 0, 0, 0, 1.2, 0, 0, 0, 1.5];
      case 'noir': return [1.1, -0.1, -0.1, -0.1, 1.1, -0.1, -0.1, -0.1, 1.1];
      case 'vintage': return [0.9, 0.2, 0.1, 0.1, 0.9, 0.1, 0.1, 0.1, 0.8];
      case 'fade': return [1.1, 0.1, 0.1, 0.1, 1.1, 0.1, 0.1, 0.1, 1.1];
      case 'chrome': return [1.2, -0.1, -0.1, 0, 1.2, 0, 0, 0, 1.2];
      case 'process': return [1.3, 0, 0, 0, 1.3, 0, 0, 0, 1.0];
      case 'transfer': return [0.9, 0.2, 0, 0.1, 0.9, 0.1, 0, 0.2, 1.0];
      default: return null;
    }
  }

  Future<Uint8List> applyBlur(Uint8List imageBytes, double radius) async {
    return await Isolate.run(() => _applyGaussianBlur(imageBytes, radius.toInt()));
  }

  static Uint8List _applyGaussianBlur(Uint8List data, int radius) {
    final image = img.decodeImage(data);
    if (image == null) return data;
    final blurred = img.gaussianBlur(image, radius: radius);
    return Uint8List.fromList(img.encodeJpg(blurred, quality: 95));
  }

  Future<Uint8List> cropImage(Uint8List imageBytes, int x, int y, int width, int height) async {
    return await Isolate.run(() => _applyCrop(imageBytes, x, y, width, height));
  }

  static Uint8List _applyCrop(Uint8List data, int x, int y, int width, int height) {
    final image = img.decodeImage(data);
    if (image == null) return data;
    final cropped = img.copyCrop(image, x: x, y: y, width: width, height: height);
    return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
  }

  Future<Uint8List> rotateImage(Uint8List imageBytes, int degrees) async {
    return await Isolate.run(() => _applyRotation(imageBytes, degrees));
  }

  static Uint8List _applyRotation(Uint8List data, int degrees) {
    final image = img.decodeImage(data);
    if (image == null) return data;
    final rotated = img.copyRotate(image, angle: degrees.toDouble());
    return Uint8List.fromList(img.encodeJpg(rotated, quality: 95));
  }

  Future<Uint8List> flipImage(Uint8List imageBytes, bool horizontal) async {
    return await Isolate.run(() => _applyFlip(imageBytes, horizontal));
  }

  static Uint8List _applyFlip(Uint8List data, bool horizontal) {
    final image = img.decodeImage(data);
    if (image == null) return data;
    final flipped = horizontal ? img.flipHorizontal(image) : img.flipVertical(image);
    return Uint8List.fromList(img.encodeJpg(flipped, quality: 95));
  }

  Future<Uint8List> compressImage(Uint8List imageBytes, int quality) async {
    return await Isolate.run(() => _applyCompression(imageBytes, quality));
  }

  static Uint8List _applyCompression(Uint8List data, int quality) {
    final image = img.decodeImage(data);
    if (image == null) return data;
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }
}