import 'dart:async';

import 'package:creator/creator.dart';
import 'package:games_services/games_services.dart' as gs;
import 'package:logging/logging.dart';

import 'score.dart';

/// Allows awarding achievements and leaderboard scores,
/// and also showing the platforms' UI overlays for achievements
/// and leaderboards.
///
/// A facade of `package:games_services`.
class GamesServicesController {
  const GamesServicesController._();

  static final Logger _log = Logger('GamesServicesController');

  static final Completer<bool> signedInCompleter = Completer();

  static final signedIn = Emitter<bool>((ref, emit) async {
    final isSignedIn = await signedInCompleter.future;
    emit(isSignedIn);
  });

  /// Unlocks an achievement on Game Center / Play Games.
  ///
  /// You must provide the achievement ids via the [iOS] and [android]
  /// parameters.
  ///
  /// Does nothing when the game isn't signed into the underlying
  /// games service.
  static Future<void> awardAchievement(Ref ref, {required String iOS, required String android}) async {
    if (!await ref.watch(signedIn)) {
      _log.warning('Trying to award achievement when not logged in.');
      return;
    }

    try {
      await gs.GamesServices.unlock(
        achievement: gs.Achievement(
          androidID: android,
          iOSID: iOS,
        ),
      );
    } catch (e) {
      _log.severe('Cannot award achievement: $e');
    }
  }

  /// Signs into the underlying games service.
  static Future<void> initialize(Ref ref) async {
    try {
      await gs.GamesServices.signIn();
      // The API is unclear so we're checking to be sure. The above call
      // returns a String, not a boolean, and there's no documentation
      // as to whether every non-error result means we're safely signed in.
      final signedIn = await gs.GamesServices.isSignedIn;
      signedInCompleter.complete(signedIn);
    } catch (e) {
      _log.severe('Cannot log into GamesServices: $e');
      signedInCompleter.complete(false);
    }
  }

  /// Launches the platform's UI overlay with achievements.
  static Future<void> showAchievements(Ref ref) async {
    if (!await ref.watch(signedIn)) {
      _log.severe('Trying to show achievements when not logged in.');
      return;
    }

    try {
      await gs.GamesServices.showAchievements();
    } catch (e) {
      _log.severe('Cannot show achievements: $e');
    }
  }

  /// Launches the platform's UI overlay with leaderboard(s).
  static Future<void> showLeaderboard(Ref ref) async {
    if (!await ref.watch(signedIn)) {
      _log.severe('Trying to show leaderboard when not logged in.');
      return;
    }

    try {
      await gs.GamesServices.showLeaderboards(
        // TODO: When ready, change both these leaderboard IDs.
        iOSLeaderboardID: "some_id_from_app_store",
        androidLeaderboardID: "sOmE_iD_fRoM_gPlAy",
      );
    } catch (e) {
      _log.severe('Cannot show leaderboard: $e');
    }
  }

  /// Submits [score] to the leaderboard.
  static Future<void> submitLeaderboardScore(Ref ref, {required Score score}) async {
    if (!await ref.watch(signedIn)) {
      _log.warning('Trying to submit leaderboard when not logged in.');
      return;
    }

    _log.info('Submitting $score to leaderboard.');

    try {
      await gs.GamesServices.submitScore(
        score: gs.Score(
          // TODO: When ready, change these leaderboard IDs.
          iOSLeaderboardID: 'some_id_from_app_store',
          androidLeaderboardID: 'sOmE_iD_fRoM_gPlAy',
          value: score.score,
        ),
      );
    } catch (e) {
      _log.severe('Cannot submit leaderboard score: $e');
    }
  }
}
