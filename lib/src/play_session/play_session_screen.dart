import 'dart:async';

import 'package:creator/creator.dart';
import 'package:flutter/material.dart';
import 'package:game_template/main.dart';
import 'package:game_template/src/ads/ads_controller.dart';
import 'package:game_template/src/audio/audio_controller.dart';
import 'package:game_template/src/in_app_purchase/in_app_purchase_controller.dart';
import 'package:game_template/src/player_progress/player_progress_controller.dart';
import 'package:game_template/src/style/palette.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart' hide Level;

import '../audio/sounds.dart';
import '../game_internals/level_controller.dart';
import '../games_services/score.dart';
import '../level_selection/levels.dart';
import '../style/confetti.dart';

class PlaySessionScreen extends StatefulWidget {
  final GameLevel level;

  const PlaySessionScreen(this.level, {super.key});

  @override
  PlaySessionScreenState createState() => PlaySessionScreenState();
}

class PlaySessionScreenState extends State<PlaySessionScreen> {
  static final _log = Logger('PlaySessionScreen');

  static const _celebrationDuration = Duration(milliseconds: 2000);

  static const _preCelebrationDuration = Duration(milliseconds: 500);

  bool _duringCelebration = false;

  late DateTime _startOfPlay;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _duringCelebration,
      child: Watcher((context, ref, _) {
        return Scaffold(
          backgroundColor: ref.watch(paletteCreator).backgroundPlaySession,
          body: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkResponse(
                        onTap: () => GoRouter.of(context).push('/settings'),
                        child: Image.asset(
                          'assets/images/settings.png',
                          semanticLabel: 'Settings',
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('Drag the slider to ${widget.level.difficulty}%'
                        ' or above!'),
                    Watcher((context, ref, _) {
                      return Slider(
                        label: 'Level Progress',
                        autofocus: true,
                        value: ref.watch(LevelController.progress) / 100,
                        onChanged: (value) => LevelController.setProgress(ref, value: (value * 100).round()),
                        onChangeEnd: (value) =>
                            LevelController.evaluate(ref, onWin: _playerWon, goal: widget.level.difficulty),
                      );
                    }),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => GoRouter.of(context).pop(),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox.expand(
                child: Visibility(
                  visible: _duringCelebration,
                  child: IgnorePointer(
                    child: Confetti(
                      isStopped: !_duringCelebration,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _startOfPlay = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Preload ad for the win screen.
    final adsRemoved = InAppPurchaseController.subscription != null
        ? context.ref.read(InAppPurchaseController.adRemoval).maybeMap(
              active: (value) => true,
              orElse: () => false,
            )
        : false;
    if (!adsRemoved && InAppPurchaseController.subscription != null) {
      AdsController.preloadAd(context.ref);
    }
  }

  Future<void> _playerWon() async {
    _log.info('Level ${widget.level.number} won');

    final score = Score(
      widget.level.number,
      widget.level.difficulty,
      DateTime.now().difference(_startOfPlay),
    );

    PlayerProgressController.setLevelReached(context.ref, level: widget.level.number);

    // Let the player see the game just after winning for a bit.
    await Future<void>.delayed(_preCelebrationDuration);
    if (!mounted) return;

    setState(() {
      _duringCelebration = true;
    });

    AudioController.playSfx(context.ref, type: SfxType.congrats);

    if (gamesServicesControllerCreator != null) {
      if (widget.level.awardsAchievement) {
        await context.ref.read(gamesServicesControllerCreator!).awardAchievement(
              android: widget.level.achievementIdAndroid!,
              iOS: widget.level.achievementIdIOS!,
            );
      }

      await context.ref.read(gamesServicesControllerCreator!).submitLeaderboardScore(score);
    }

    /// Give the player some time to see the celebration animation.
    await Future<void>.delayed(_celebrationDuration);
    if (!mounted) return;

    GoRouter.of(context).go('/play/won', extra: {'score': score});
  }
}
