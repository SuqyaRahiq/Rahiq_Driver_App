import 'dart:async';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';

class MediaCompressor {
  static Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } catch (_) {}
  }

  static const int _targetImageBytes = 1 * 1024 * 1024;

  // Ordered from highest quality/resolution to most aggressive. Each entry
  // is tried in turn and the first one landing under [_targetImageBytes] is
  // used, so the image keeps the highest resolution/quality that still fits
  // the target size instead of always compressing to a fixed, lower preset.
  static const List<(int quality, int dimension)> _imageCompressionSteps = [
    (90, 2400),
    (80, 2400),
    (75, 1920),
    (65, 1600),
    (55, 1280),
    (40, 1024),
  ];

  /// Compresses an image, trying progressively lower quality/resolution
  /// steps until the result fits under 1MB.
  static Future<String?> compressImage(String path) async {
    try {
      final originalFile = File(path);
      if (!originalFile.existsSync()) return path;

      final tempDir = await getTemporaryDirectory();

      File? smallestResult;
      int? smallestSize;

      for (final step in _imageCompressionSteps) {
        final (quality, dimension) = step;
        final targetPath =
            '${tempDir.path}/comp_${DateTime.now().microsecondsSinceEpoch}.jpg';

        final result = await FlutterImageCompress.compressAndGetFile(
          path,
          targetPath,
          quality: quality,
          minWidth: dimension,
          minHeight: dimension,
        );
        if (result == null) continue;

        final size = await result.length();

        if (size <= _targetImageBytes) {
          if (smallestResult != null) unawaited(_deleteQuietly(smallestResult));
          return result.path;
        }

        if (smallestSize == null || size < smallestSize) {
          if (smallestResult != null) unawaited(_deleteQuietly(smallestResult));
          smallestResult = File(result.path);
          smallestSize = size;
        } else {
          unawaited(_deleteQuietly(File(result.path)));
        }
      }

      if (smallestResult != null) {
        return smallestResult.path;
      }
    } catch (_) {
      // Compression is optional: fall back to the original file.
    }
    return path;
  }

  /// Compresses a video. Always returns
  /// a path ending in `.mp4` — the video/audio content is untouched, only
  /// the container is normalized, since some sources (e.g. iOS camera
  /// recordings) hand back a `.mov` file.
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
        return _ensureMp4Extension(info.file!.path);
      }
    } catch (_) {
      // Compression is optional: fall back to the original file.
    }
    return _ensureMp4Extension(path);
  }

  /// Returns [path] unchanged if it already has an `.mp4` extension,
  /// otherwise copies it to a new file with an `.mp4` extension and returns
  /// that new path. Used as a safety net for when video compression fails
  /// and we'd otherwise fall back to a source file in a different container
  /// (e.g. `.mov` from the iOS camera).
  static Future<String> _ensureMp4Extension(String path) async {
    if (path.toLowerCase().endsWith('.mp4')) return path;
    try {
      final tempDir = await getTemporaryDirectory();
      final newPath =
          '${tempDir.path}/video_${DateTime.now().microsecondsSinceEpoch}.mp4';
      await File(path).copy(newPath);
      return newPath;
    } catch (e) {
      return path;
    }
  }
}
