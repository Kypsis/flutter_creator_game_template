import 'package:creator/creator.dart';
import 'package:flutter/material.dart';
import 'package:game_template/src/ads/ads_controller.dart';
import 'package:game_template/src/in_app_purchase/in_app_purchase_controller.dart';
import 'package:game_template/src/style/palette.dart';
import 'package:go_router/go_router.dart';

import '../ads/banner_ad_widget.dart';
import '../games_services/score.dart';
import '../style/responsive_screen.dart';

class WinGameScreen extends StatelessWidget {
  final Score score;

  const WinGameScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 10);

    return Watcher((context, ref, _) {
      final adsControllerAvailable = context.ref.watch(AdsController.preloadedAd) != null;

      final adsRemoved = InAppPurchaseController.subscription != null
          ? context.ref.watch(InAppPurchaseController.adRemoval).maybeMap(
                active: (value) => true,
                orElse: () => false,
              )
          : false;

      return Scaffold(
        backgroundColor: context.ref.watch(paletteCreator).backgroundPlaySession,
        body: ResponsiveScreen(
          squarishMainArea: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (adsControllerAvailable && !adsRemoved) ...[
                const Expanded(
                  child: Center(
                    child: BannerAdWidget(),
                  ),
                ),
              ],
              gap,
              const Center(
                child: Text(
                  'You won!',
                  style: TextStyle(fontFamily: 'Permanent Marker', fontSize: 50),
                ),
              ),
              gap,
              Center(
                child: Text(
                  'Score: ${score.score}\n'
                  'Time: ${score.formattedTime}',
                  style: const TextStyle(fontFamily: 'Permanent Marker', fontSize: 20),
                ),
              ),
            ],
          ),
          rectangularMenuArea: ElevatedButton(
            onPressed: () {
              GoRouter.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ),
      );
    });
  }
}
