import 'package:creator/creator.dart';
import 'package:flutter/foundation.dart';
import 'package:game_template/src/settings/persistence/local_storage_settings_persistence.dart';

import 'persistence/settings_persistence.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to persistence store.
class SettingsController {
  SettingsController._();

  static final playerName = Creator.value("Player");
  static final muted = Creator.value(false);
  static final musicOn = Creator.value(true);
  static final soundsOn = Creator.value(true);

  static final SettingsPersistence _persistence = LocalStorageSettingsPersistence();

  /// Asynchronously loads values from the injected persistence store.
  static Future<void> loadStateFromPersistence(Ref ref) async {
    await Future.wait([
      _persistence.getPlayerName().then((value) => ref.set(playerName, value)),
      _persistence.getMusicOn().then((value) => ref.set(musicOn, value)),
      _persistence.getSoundsOn().then((value) => ref.set(soundsOn, value)),
      _persistence
          // On the web, sound can only start after user interaction, so
          // we start muted there.
          // On any other platform, we start unmuted.
          .getMuted(defaultValue: kIsWeb)
          .then((value) => ref.set(muted, value)),
    ]);
  }

  static void setPlayerName(Ref ref, {required String name}) {
    ref.update<String>(playerName, (state) => name);
    _persistence.savePlayerName(ref.read(playerName));
  }

  static void toggleMusicOn(Ref ref) {
    ref.update<bool>(musicOn, (state) => !state);
    _persistence.saveMusicOn(ref.read(musicOn));
  }

  static void toggleSoundsOn(Ref ref) {
    ref.update<bool>(soundsOn, (state) => !state);
    _persistence.saveSoundsOn(ref.read(soundsOn));
  }

  static void toggleMuted(Ref ref) {
    ref.update<bool>(muted, (state) => !state);
    _persistence.saveMuted(ref.read(muted));
  }
}
