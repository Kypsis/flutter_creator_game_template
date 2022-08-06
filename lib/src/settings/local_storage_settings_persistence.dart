import 'package:shared_preferences/shared_preferences.dart';

/// Use `package:shared_preferences`.
class LocalStorageSettingsPersistence {
  const LocalStorageSettingsPersistence._();

  static final Future<SharedPreferences> instanceFuture = SharedPreferences.getInstance();

  static Future<bool> getMusicOn() async {
    final prefs = await instanceFuture;
    return prefs.getBool('musicOn') ?? true;
  }

  static Future<bool> getMuted({required bool defaultValue}) async {
    final prefs = await instanceFuture;
    return prefs.getBool('mute') ?? defaultValue;
  }

  static Future<String> getPlayerName() async {
    final prefs = await instanceFuture;
    return prefs.getString('playerName') ?? 'Player';
  }

  static Future<bool> getSoundsOn() async {
    final prefs = await instanceFuture;
    return prefs.getBool('soundsOn') ?? true;
  }

  static Future<void> saveMusicOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('musicOn', value);
  }

  static Future<void> saveMuted(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('mute', value);
  }

  static Future<void> savePlayerName(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('playerName', value);
  }

  static Future<void> saveSoundsOn(bool value) async {
    final prefs = await instanceFuture;
    await prefs.setBool('soundsOn', value);
  }
}
