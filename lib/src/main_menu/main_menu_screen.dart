import 'package:creator/creator.dart';
import 'package:flutter/material.dart';
import 'package:game_template/src/audio/audio_controller.dart';
import 'package:game_template/src/games_services/games_services.dart';
import 'package:game_template/src/settings/settings_controller.dart';
import 'package:game_template/src/style/palette.dart';
import 'package:go_router/go_router.dart';

import '../audio/sounds.dart';
import '../style/responsive_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Watcher((context, ref, _) {
      return Scaffold(
        backgroundColor: ref.watch(paletteCreator).backgroundMain,
        body: ResponsiveScreen(
          mainAreaProminence: 0.45,
          squarishMainArea: Center(
            child: Transform.rotate(
              angle: -0.1,
              child: const Text(
                'Flutter Game Template!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Permanent Marker',
                  fontSize: 55,
                  height: 1,
                ),
              ),
            ),
          ),
          rectangularMenuArea: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  AudioController.playSfx(ref, type: SfxType.buttonTap);
                  GoRouter.of(context).go('/play');
                },
                child: const Text('Play'),
              ),
              _gap,
              if (ref.watch(GamesServicesController.signedIn.asyncData).data == true) ...[
                _hideUntilReady(
                  ready: ref.watch(GamesServicesController.signedIn),
                  child: ElevatedButton(
                    onPressed: () => GamesServicesController.showAchievements(ref),
                    child: const Text('Achievements'),
                  ),
                ),
                _gap,
                _hideUntilReady(
                  ready: ref.watch(GamesServicesController.signedIn),
                  child: ElevatedButton(
                    onPressed: () => GamesServicesController.showLeaderboard(ref),
                    child: const Text('Leaderboard'),
                  ),
                ),
                _gap,
              ],
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/settings'),
                child: const Text('Settings'),
              ),
              _gap,
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Watcher(
                  (context, ref, child) {
                    return IconButton(
                      onPressed: () => SettingsController.toggleMuted(ref),
                      icon: Icon(ref.watch(SettingsController.muted) ? Icons.volume_off : Icons.volume_up),
                    );
                  },
                ),
              ),
              _gap,
              const Text('Music by Mr Smith'),
              _gap,
            ],
          ),
        ),
      );
    });
  }

  /// Prevents the game from showing game-services-related menu items
  /// until we're sure the player is signed in.
  ///
  /// This normally happens immediately after game start, so players will not
  /// see any flash. The exception is folks who decline to use Game Center
  /// or Google Play Game Services, or who haven't yet set it up.
  Widget _hideUntilReady({required Widget child, required Future<bool> ready}) {
    return FutureBuilder<bool>(
      future: ready,
      builder: (context, snapshot) {
        // Use Visibility here so that we have the space for the buttons
        // ready.
        return Visibility(
          visible: snapshot.data ?? false,
          maintainState: true,
          maintainSize: true,
          maintainAnimation: true,
          child: child,
        );
      },
    );
  }

  static const _gap = SizedBox(height: 10);
}
