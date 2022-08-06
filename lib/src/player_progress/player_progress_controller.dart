import 'dart:async';

import 'package:creator/creator.dart';
import 'package:game_template/src/player_progress/local_storage_player_progress_persistence.dart';

class PlayerProgressController {
  static const maxHighestScoresPerPlayer = 10;

  static final highestLevelReached = Creator.value(0, keepAlive: true);

  static Future<void> getLatestFromStore(Ref ref) async {
    final level = await LocalStoragePlayerProgressPersistence.getHighestLevelReached();
    if (level > ref.read(highestLevelReached)) {
      ref.set(highestLevelReached, level);
    } else if (level < ref.read(highestLevelReached)) {
      await LocalStoragePlayerProgressPersistence.saveHighestLevelReached(ref.read(highestLevelReached));
    }
  }

  static void reset(Ref ref) {
    ref.set(highestLevelReached, 0);
    LocalStoragePlayerProgressPersistence.saveHighestLevelReached(ref.read(highestLevelReached));
  }

  static void setLevelReached(Ref ref, {required int level}) {
    if (level > ref.read(highestLevelReached)) {
      ref.set(highestLevelReached, level);

      unawaited(LocalStoragePlayerProgressPersistence.saveHighestLevelReached(ref.read(highestLevelReached)));
    }
  }
}
