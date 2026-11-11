import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

class MediaCompressor {
  /// Compresses an image.
  static Future<String?> compressImage(String path) async {
    try {
      final originalFile = File(path);
      if (!originalFile.existsSync()) return path;

      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 70,
      );

      if (result != null) {
        return result.path;
      }
    } catch (_) {
      // Compression is optional: fall back to the original file.
    }
    return path;
  }

  /// Compresses a video.
  static Future<String?> compressVideo(String path) async {
    try {
      final originalFile = File(path);
      if (!originalFile.existsSync()) return path;

      final info = await VideoCompress.compressVideo(
        path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        return info.file!.path;
      }
    } catch (_) {
      // Compression is optional: fall back to the original file.
    }
    return path;
  }
}
