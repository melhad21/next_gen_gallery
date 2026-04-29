class AppConstants {
  static const String appName = 'Antigravity Gallery';
  static const String appVersion = '1.0.0';

  static const String keyVaultPin = 'vault_pin';
  static const String keyVaultEnabled = 'vault_enabled';
  static const String keyDecoyMode = 'decoy_mode';
  static const String keyLastDeletedCleanup = 'last_deleted_cleanup';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyGridColumns = 'grid_columns';
  static const String keyAIEnabled = 'ai_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyVaultSetup = 'vault_setup_complete';

  static const String vaultDirName = '.antigravity_vault';
  static const String decoyDirName = 'HiddenPictures';
  static const String trashDirName = '.trash';
  static const String nomediaFile = '.nomedia';
  static const String decoyNomedia = '.nomedia';

  static const List<String> aiCategories = [
    'Selfies',
    'Food',
    'Pets',
    'Documents',
    'Landscapes',
    'Screenshots',
    'Travel',
    'Social',
    'Art',
    'Nature',
  ];

  static const List<String> supportedImageExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'dng', 'raw', 'svg'
  ];
  static const List<String> supportedVideoExtensions = [
    'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'wmv', 'flv'
  ];

  static const int trashRetentionDays = 30;
  static const int minGridColumns = 2;
  static const int maxGridColumns = 6;
  static const int defaultGridColumns = 4;
  static const int thumbnailSize = 300;
  static const int pageSize = 100;

  static const List<double> videoSpeeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0];

  static const Map<String, String> labelToCategory = {
    'person': 'Selfies',
    'selfie': 'Selfies',
    'food': 'Food',
    'dish': 'Food',
    'pizza': 'Food',
    'cake': 'Food',
    'dog': 'Pets',
    'cat': 'Pets',
    'pet': 'Pets',
    'bird': 'Pets',
    'fish': 'Pets',
    'document': 'Documents',
    'receipt': 'Documents',
    'text': 'Documents',
    'paper': 'Documents',
    'sky': 'Landscapes',
    'mountain': 'Landscapes',
    'beach': 'Landscapes',
    'sunset': 'Landscapes',
    'sunrise': 'Landscapes',
    'tree': 'Landscapes',
    'forest': 'Landscapes',
    'screenshot': 'Screenshots',
    'screen': 'Screenshots',
    'car': 'Travel',
    'building': 'Travel',
    'city': 'Travel',
    'airplane': 'Travel',
    'train': 'Travel',
    'art': 'Art',
    'painting': 'Art',
    'sculpture': 'Art',
    'flower': 'Nature',
    'plant': 'Nature',
    'animal': 'Nature',
  };
}