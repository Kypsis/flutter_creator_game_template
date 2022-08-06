import 'package:creator/creator.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'preloaded_banner_ad.dart';

/// Allows showing ads. A facade for `package:google_mobile_ads`.
class AdsController {
  const AdsController._();

  static final MobileAds _instance = MobileAds.instance;

  static final preloadedAd = Creator<PreloadedBannerAd?>.value(null);

  static void dispose(Ref ref) {
    ref.read(preloadedAd)?.dispose();
  }

  /// Initializes the injected [MobileAds.instance].
  static Future<void> initialize() async {
    await _instance.initialize();
  }

  /// Starts preloading an ad to be used later.
  ///
  /// The work doesn't start immediately so that calling this doesn't have
  /// adverse effects (jank) during start of a new screen.
  static void preloadAd(Ref ref) {
    // TODO: When ready, change this to the Ad Unit IDs provided by AdMob.
    //       The current values are AdMob's sample IDs.
    final adUnitId = defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-3940256099942544/6300978111'
        // iOS
        : 'ca-app-pub-3940256099942544/2934735716';
    ref.set(preloadedAd, PreloadedBannerAd(size: AdSize.mediumRectangle, adUnitId: adUnitId));

    // Wait a bit so that calling at start of a new screen doesn't have
    // adverse effects on performance.
    Future<void>.delayed(const Duration(seconds: 1)).then((_) {
      return ref.read(preloadedAd)!.load();
    });
  }

  /// Allows caller to take ownership of a [PreloadedBannerAd].
  ///
  /// If this method returns a non-null value, then the caller is responsible
  /// for disposing of the loaded ad.
  static PreloadedBannerAd? takePreloadedAd(Ref ref) {
    final ad = ref.watch(preloadedAd);
    ref.set(preloadedAd, null);
    return ad;
  }
}
