import 'package:creator/creator.dart';
import 'package:flutter/foundation.dart';
import 'package:game_template/src/settings/persistence/local_storage_settings_persistence.dart';

/// An class that holds settings like [playerName] or [musicOn],
/// and saves them to persistence store.
class SettingsController {
  SettingsController._();

  static final playerName = Creator.value("Player", keepAlive: true);
  static final muted = Creator.value(true, keepAlive: true);
  static final musicOn = Creator.value(true, keepAlive: true);
  static final soundsOn = Creator.value(true, keepAlive: true);

  /// Asynchronously loads values from the injected persistence store.
  static Future<void> loadStateFromPersistence(Ref ref) async {
    await Future.wait([
      LocalStorageSettingsPersistence.getPlayerName().then((value) => ref.set(playerName, value)),
      LocalStorageSettingsPersistence.getMusicOn().then((value) => ref.set(musicOn, value)),
      LocalStorageSettingsPersistence.getSoundsOn().then((value) => ref.set(soundsOn, value)),
      LocalStorageSettingsPersistence
              // On the web, sound can only start after user interaction, so
              // we start muted there.
              // On any other platform, we start unmuted.
              .getMuted(defaultValue: kIsWeb)
          .then((value) => ref.set(muted, value)),
    ]);
  }

  static void setPlayerName(Ref ref, {required String name}) {
    ref.update<String>(playerName, (state) => name);
    LocalStorageSettingsPersistence.savePlayerName(ref.read(playerName));
  }

  static void toggleMusicOn(Ref ref) {
    ref.update<bool>(musicOn, (state) => !state);
    LocalStorageSettingsPersistence.saveMusicOn(ref.read(musicOn));
  }

  static void toggleSoundsOn(Ref ref) {
    ref.update<bool>(soundsOn, (state) => !state);
    LocalStorageSettingsPersistence.saveSoundsOn(ref.read(soundsOn));
  }

  static void toggleMuted(Ref ref) {
    ref.update<bool>(muted, (state) => !state);
    LocalStorageSettingsPersistence.saveMuted(ref.read(muted));
  }
}
