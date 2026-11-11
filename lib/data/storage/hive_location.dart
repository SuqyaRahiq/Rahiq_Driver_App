import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// The folder Hive keeps its boxes in, ready to pass to `Hive.init`.
///
/// Application Support, not Documents (where `Hive.initFlutter()` puts them).
/// Documents is the folder iOS shows in the Files app as soon as file sharing
/// is switched on, which would put the auth box (session tokens, driver
/// profile) in front of anyone holding the phone. Application Support is never
/// shown there, but it is kept across launches and app updates and backed up
/// just like Documents, so sessions persist exactly as before.
///
/// Boxes an earlier version left in Documents are moved here first, so a
/// driver who updates stays signed in.
Future<String> prepareHivePath(List<String> boxNames) async {
  final dir = await getApplicationSupportDirectory();
  try {
    await moveHiveBoxes(
      from: await getApplicationDocumentsDirectory(),
      to: dir,
      boxNames: boxNames,
    );
  } catch (_) {
    // A box that fails to move only means signing in again, which is not
    // worth blocking startup over.
  }
  return dir.path;
}

/// Moves the files of [boxNames] from [from] to [to], then deletes whatever
/// is left of them in [from] so nothing stays visible in the Files app.
///
/// Runs on every launch and does nothing once [from] is clean. A box already
/// in [to] is never overwritten: the copy in [from] is stale and is dropped.
Future<void> moveHiveBoxes({
  required Directory from,
  required Directory to,
  required List<String> boxNames,
}) async {
  await to.create(recursive: true);

  for (final boxName in boxNames) {
    // Hive names every box file after the lowercased box name.
    final name = boxName.toLowerCase();

    if (!await File('${to.path}/$name.hive').exists()) {
      // A `.hivec` is a compaction Hive did not finish. Hive recovers it when
      // the box opens, so it moves with the box.
      for (final ext in ['hive', 'hivec']) {
        final file = File('${from.path}/$name.$ext');
        if (await file.exists()) await file.rename('${to.path}/$name.$ext');
      }
    }

    for (final ext in ['hive', 'hivec', 'lock']) {
      final file = File('${from.path}/$name.$ext');
      if (await file.exists()) await file.delete();
    }
  }
}
