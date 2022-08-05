import 'package:creator/creator.dart';
import 'package:flutter/foundation.dart';

/// An extremely silly example of a game state.
///
/// Tracks only a single variable, [progress], and calls [onWin] when
/// the value of [progress] reaches [goal].

class LevelController {
  const LevelController._();

  static final progress = Creator.value(0);

  static void setProgress(Ref ref, {required int value}) {
    ref.set(progress, value);
  }

  static void evaluate(Ref ref, {required VoidCallback onWin, int goal = 100}) {
    if (ref.read(progress) >= goal) {
      onWin();
    }
  }
}
