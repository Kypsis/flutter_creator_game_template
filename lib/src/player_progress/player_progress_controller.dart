import 'dart:async';

import 'package:creator/creator.dart';
import 'package:game_template/src/player_progress/persistence/local_storage_player_progress_persistence.dart';

/// Encapsulates the player's progress.
class PlayerProgressController {
  static const maxHighestScoresPerPlayer = 10;

  /// The highest level that the player has reached so far.
  static final highestLevelReached = Creator.value(0, keepAlive: true);

  /// Fetches the latest data from the backing persistence store.
  static Future<void> getLatestFromStore(Ref ref) async {
    final level = await LocalStoragePlayerProgressPersistence.getHighestLevelReached();
    if (level > ref.read(highestLevelReached)) {
      ref.set(highestLevelReached, level);
    } else if (level < ref.read(highestLevelReached)) {
      await LocalStoragePlayerProgressPersistence.saveHighestLevelReached(ref.read(highestLevelReached));
    }
  }

  /// Resets the player's progress so it's like if they just started
  /// playing the game for the first time.
  static void reset(Ref ref) {
    ref.set(highestLevelReached, 0);
    LocalStoragePlayerProgressPersistence.saveHighestLevelReached(ref.read(highestLevelReached));
  }

  /// Registers [level] as reached.
  ///
  /// If this is higher than [highestLevelReached], it will update that
  /// value and save it to the injected persistence store.
  static void setLevelReached(Ref ref, {required int level}) {
    if (level > ref.read(highestLevelReached)) {
      ref.set(highestLevelReached, level);

      unawaited(LocalStoragePlayerProgressPersistence.saveHighestLevelReached(ref.read(highestLevelReached)));
    }
  }
}
