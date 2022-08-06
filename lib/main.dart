// Uncomment the following lines when enabling Firebase Crashlytics
// import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

import 'dart:io';

import 'package:creator/creator.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_template/router.dart';
import 'package:game_template/src/audio/audio_controller.dart';
import 'package:game_template/src/player_progress/player_progress_controller.dart';
import 'package:game_template/src/settings/settings_controller.dart';

import 'package:logging/logging.dart';

import 'src/ads/ads_controller.dart';
import 'src/crashlytics/crashlytics.dart';
import 'src/games_services/games_services.dart';
import 'src/in_app_purchase/in_app_purchase_controller.dart';
import 'src/style/palette.dart';
import 'src/style/snack_bar.dart';

Future<void> main() async {
  // To enable Firebase Crashlytics, uncomment the following lines and
  // the import statements at the top of this file.
  // See the 'Crashlytics' section of the main README.md file for details.

  FirebaseCrashlytics? crashlytics;
  // if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
  //   try {
  //     WidgetsFlutterBinding.ensureInitialized();
  //     await Firebase.initializeApp(
  //       options: DefaultFirebaseOptions.currentPlatform,
  //     );
  //     crashlytics = FirebaseCrashlytics.instance;
  //   } catch (e) {
  //     debugPrint("Firebase couldn't be initialized: $e");
  //   }
  // }

  await guardWithCrashlytics(
    guardedMain,
    crashlytics: crashlytics,
  );
}

/// Without logging and crash reporting, this would be `void main()`.
void guardedMain() {
  if (kReleaseMode) {
    // Don't log anything below warnings in production.
    Logger.root.level = Level.WARNING;
  }
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: '
        '${record.loggerName}: '
        '${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  _log.info('Going full screen');
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  runApp(
    CreatorGraph(
      child: const MyApp(),
    ),
  );
}

Logger _log = Logger('main.dart');

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    PlayerProgressController.getLatestFromStore(context.ref);
    SettingsController.loadStateFromPersistence(context.ref);
    AudioController.initialize(context.ref);

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) AdsController.initialize();
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) GamesServicesController.initialize(context.ref);
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) InAppPurchaseController.subscribe(context.ref);
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) InAppPurchaseController.restorePurchases(context.ref);
  }

  @override
  void dispose() {
    AdsController.dispose(context.ref);
    AudioController.dispose();
    InAppPurchaseController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watcher(
      null,
      listener: (ref) {
        ref.watch(SettingsController.muted);
        ref.watch(SettingsController.musicOn);
        AudioController.musicHandler(ref);
      },
      child: MaterialApp.router(
        title: 'Flutter Demo',
        theme: ThemeData.from(
          colorScheme: ColorScheme.fromSeed(
            seedColor: context.ref.watch(paletteCreator).darkPen,
            background: context.ref.watch(paletteCreator).backgroundMain,
          ),
          textTheme: TextTheme(
            bodyText2: TextStyle(
              color: context.ref.watch(paletteCreator).ink,
            ),
          ),
        ),
        routeInformationParser: context.ref.watch(Routing.goRouter).routeInformationParser,
        routeInformationProvider: context.ref.read(Routing.goRouter).routeInformationProvider,
        routerDelegate: context.ref.read(Routing.goRouter).routerDelegate,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    );
  }
}
