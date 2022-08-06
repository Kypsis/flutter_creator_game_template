import 'package:creator/creator.dart';
import 'package:flutter/material.dart';
import 'package:game_template/src/audio/audio_controller.dart';
import 'package:game_template/src/player_progress/player_progress_controller.dart';
import 'package:game_template/src/style/palette.dart';
import 'package:go_router/go_router.dart';

import '../audio/sounds.dart';
import '../style/responsive_screen.dart';
import 'levels.dart';

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Watcher((context, ref, _) {
      return Scaffold(
        backgroundColor: ref.watch(paletteCreator).backgroundLevelSelection,
        body: ResponsiveScreen(
          squarishMainArea: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Select level',
                    style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Expanded(
                child: ListView(
                  children: [
                    for (final level in gameLevels)
                      Watcher((context, ref, _) {
                        return ListTile(
                          enabled: ref.watch(PlayerProgressController.highestLevelReached) >= level.number - 1,
                          onTap: () {
                            AudioController.playSfx(ref, type: SfxType.buttonTap);

                            GoRouter.of(context).go('/play/session/${level.number}');
                          },
                          leading: Text(level.number.toString()),
                          title: Text('Level #${level.number}'),
                        );
                      })
                  ],
                ),
              ),
            ],
          ),
          rectangularMenuArea: ElevatedButton(
            onPressed: () {
              GoRouter.of(context).pop();
            },
            child: const Text('Back'),
          ),
        ),
      );
    });
  }
}
