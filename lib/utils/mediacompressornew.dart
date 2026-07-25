import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

class MediaCompressor {
  /// Compresses an image and logs its size before and after.
  static Future<String?> compressImage(String path) async {
    try {
      final originalFile = File(path);
      if (!originalFile.existsSync()) return path;

      final originalSize = await originalFile.length();
      debugPrint('📸 [MediaCompressor] Original Image Size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 70,
      );

      if (result != null) {
        final newSize = await result.length();
        debugPrint('📸 [MediaCompressor] Compressed Image Size: ${(newSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        return result.path;
      }
    } catch (e) {
      debugPrint('📸 [MediaCompressor] Image compression error: $e');
    }
    return path;
  }

  /// Compresses a video and logs its size before and after.
  static Future<String?> compressVideo(String path) async {
    try {
      final originalFile = File(path);
      if (!originalFile.existsSync()) return path;

      final originalSize = await originalFile.length();
      debugPrint('🎥 [MediaCompressor] Original Video Size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB');

      final info = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        final newSize = await info.file!.length();
        debugPrint('🎥 [MediaCompressor] Compressed Video Size: ${(newSize / (1024 * 1024)).toStringAsFixed(2)} MB');
        debugPrint('🎥 [MediaCompressor] Compressed Video Resolution: ${info.width}x${info.height}');
        debugPrint('🎥 [MediaCompressor] Compressed Video Duration: ${info.duration?.toStringAsFixed(2)} seconds');
        return info.file!.path;
      }
    } catch (e) {
      debugPrint('🎥 [MediaCompressor] Video compression error: $e');
    }
    return path;
  }
}
