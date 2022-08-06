import 'dart:collection';
import 'dart:math';

// ignore: depend_on_referenced_packages
import 'package:audioplayers/audioplayers.dart' hide Logger;
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
  }

  static void dispose() {
    FlameAudio.bgm.dispose();
    FlameAudio.audioCache.clearAll();
    _audioCache.clear();
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

  static void musicHandler(Ref ref) {
    if (ref.read(SettingsController.musicOn) && !ref.read(SettingsController.muted)) {
      // Music got turned on.
      _resumeMusic();
    } else {
      // Music got turned off.
      _stopMusic();
    }
  }

  static Future<void> _resumeMusic() async {
    _log.info('Resuming music');

    switch (FlameAudio.bgm.audioPlayer?.state) {
      case PlayerState.PAUSED:
        _log.info('Calling _musicPlayer.resume()');
        try {
          await FlameAudio.bgm.resume();
        } catch (e) {
          // Sometimes, resuming fails with an "Unexpected" error.
          _log.severe(e);
          await FlameAudio.bgm.play("music/${_playlist.first.filename}");
        }
        break;
      case PlayerState.STOPPED:
        _log.info("resumeMusic() called when music is stopped. "
            "This probably means we haven't yet started the music. "
            "For example, the game was started with sound off.");
        await FlameAudio.bgm.play("music/${_playlist.first.filename}");
        break;
      case PlayerState.PLAYING:
        _log.warning('resumeMusic() called when music is playing. '
            'Nothing to do.');
        break;
      case PlayerState.COMPLETED:
        _log.warning('resumeMusic() called when music is completed. '
            "Music should never be 'completed' as it's either not playing "
            "or looping forever.");
        await FlameAudio.bgm.play("music/${_playlist.first.filename}");
        break;
      default:
        await FlameAudio.bgm.play("music/${_playlist.first.filename}");
        break;
    }
  }

  static void _stopMusic() {
    _log.info('Stopping music');

    FlameAudio.bgm.pause();
  }
}
