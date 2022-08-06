import 'package:shared_preferences/shared_preferences.dart';

/// Use `package:shared_preferences`.
class LocalStoragePlayerProgressPersistence {
  static final Future<SharedPreferences> instanceFuture = SharedPreferences.getInstance();

  static Future<int> getHighestLevelReached() async {
    final prefs = await instanceFuture;
    return prefs.getInt('highestLevelReached') ?? 0;
  }

  static Future<void> saveHighestLevelReached(int level) async {
    final prefs = await instanceFuture;
    await prefs.setInt('highestLevelReached', level);
  }
}
