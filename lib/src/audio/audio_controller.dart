import 'dart:collection';
import 'dart:math';

import 'package:creator/creator.dart';
import 'package:flame_audio/audio_pool.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:logging/logging.dart';

import '../settings/settings_controller.dart';
import 'songs.dart';
import 'sounds.dart';

// TODO: check if later versions of flame_audio (and underlying audioplayers library) has fixed audio on android
class AudioController {
  AudioController._();

  static final _log = Logger('AudioController');

  static final Queue<Song> _playlist = Queue.of(List<Song>.of(songs)..shuffle());

  static final Random _random = Random();

  static late List<Uri> _audioCache;

  static Future<void> initialize(Ref ref) async {
    _log.info('Preloading sound effects');

    _audioCache = await FlameAudio.audioCache
        .loadAll(SfxType.values.expand(soundTypeToFilename).map((sound) => "sfx/$sound").toList());

    for (var uri in _audioCache) {
      await AudioPool.create(
        uri.pathSegments.last,
        minPlayers: 3,
        maxPlayers: 4,
      );
    }

    FlameAudio.bgm.initialize();
    FlameAudio.bgm.audioPlayer?.onPlayerCompletion.listen(_changeSong);

    if (!ref.watch(SettingsController.muted) && ref.watch(SettingsController.musicOn)) {
      _startMusic();
    }
  }

  /// Plays a single sound effect, defined by [type].
  ///
  /// The controller will ignore this call when the attached settings'
  /// [SettingsController.muted] is `true` or if its
  /// [SettingsController.soundsOn] is `false`.
  static void playSfx(Ref ref, {required SfxType type}) {
    final muted = ref.read(SettingsController.muted);
    if (muted) {
      _log.info(() => 'Ignoring playing sound ($type) because audio is muted.');
      return;
    }

    final soundsOn = ref.read(SettingsController.soundsOn);
    if (!soundsOn) {
      _log.info(() => 'Ignoring playing sound ($type) because sounds are turned off.');
      return;
    }

    _log.info(() => 'Playing sound: $type');
    final options = soundTypeToFilename(type);
    final filename = options[_random.nextInt(options.length)];
    _log.info(() => '- Chosen filename: $filename');

    FlameAudio.play("sfx/$filename");
  }

  static void _changeSong(void _) {
    _log.info('Last song finished playing.');
    // Put the song that just finished playing to the end of the playlist.
    _playlist.addLast(_playlist.removeFirst());
    // Play the next song.
    _log.info(() => 'Playing ${_playlist.first} now.');
    FlameAudio.bgm.play("music/${_playlist.first.filename}");
  }

  static void musicOnHandler(Ref ref) {
    if (ref.read(SettingsController.musicOn)) {
      // Music got turned on.
      if (!ref.read(SettingsController.muted)) {
        _resumeMusic();
      }
    } else {
      // Music got turned off.
      _stopMusic();
    }
  }

  static void mutedHandler(Ref ref) {
    if (ref.read(SettingsController.muted)) {
      // All sound just got muted.
      _stopAllSound();
    } else {
      // All sound just got un-muted.
      if (ref.read(SettingsController.musicOn)) {
        _resumeMusic();
      }
    }
  }

  static Future<void> _resumeMusic() async {
    _log.info('Resuming music');

    try {
      await FlameAudio.bgm.resume();
    } catch (e) {
      // Sometimes, resuming fails with an "Unexpected" error.
      _log.severe(e);
      await FlameAudio.bgm.play("music/${_playlist.first.filename}");
    }
  }

  static void _startMusic() {
    _log.info('starting music');
    FlameAudio.bgm.play("music/${_playlist.first.filename}");
  }

  static void _stopAllSound() {
    FlameAudio.bgm.pause();
  }

  static void _stopMusic() {
    _log.info('Stopping music');

    FlameAudio.bgm.pause();
  }
}
