import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  bool musicOn = true;
  bool sfxOn = true;
  bool vibrationOn = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  bool tutorialSeen = false;

  static const _key = 'pucket_settings';
  static const _tutorialKey = 'pucket_tutorial_seen';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tutorialSeen = prefs.getBool(_tutorialKey) ?? false;
    final json = prefs.getString(_key);
    if (json == null) {
      notifyListeners();
      return;
    }
    try {
      final parts = json.split('|');
      if (parts.length >= 5) {
        musicOn = parts[0] == '1';
        sfxOn = parts[1] == '1';
        vibrationOn = parts[2] == '1';
        musicVolume = double.tryParse(parts[3]) ?? 0.7;
        sfxVolume = double.tryParse(parts[4]) ?? 0.8;
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> markTutorialSeen() async {
    tutorialSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      '${musicOn ? 1 : 0}|${sfxOn ? 1 : 0}|${vibrationOn ? 1 : 0}|$musicVolume|$sfxVolume',
    );
  }

  void setMusic(bool v) {
    musicOn = v;
    notifyListeners();
    save();
  }

  void setSfx(bool v) {
    sfxOn = v;
    notifyListeners();
    save();
  }

  void setVibration(bool v) {
    vibrationOn = v;
    notifyListeners();
    save();
  }

  void setMusicVolume(double v) {
    musicVolume = v;
    notifyListeners();
    save();
  }

  void setSfxVolume(double v) {
    sfxVolume = v;
    notifyListeners();
    save();
  }
}
