import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../l10n/app_localizations.dart';

class SettingsService extends ChangeNotifier {
  bool musicOn = true;
  bool sfxOn = true;
  bool vibrationOn = true;
  double musicVolume = 0.7;
  double sfxVolume = 0.8;
  bool tutorialSeen = false;
  bool firstMatchPlayed = false;
  bool adsRemoved = false;
  bool reachabilityHintShown = false;
  /// Son "kolay" yapay zekâ rakipten bu yana oynanan maç sayısı. Oyuncu üst üste
  /// kaybedip oyundan kopmasın diye periyodik olarak kolay rakip verilir.
  int botMatchesSinceEasy = 0;
  AppLanguage language = AppLanguage.tr;

  static const _key = 'pucket_settings';
  static const _tutorialKey = 'pucket_tutorial_seen';
  static const _firstMatchKey = 'pucket_first_match_played';
  static const _adsRemovedKey = 'pucket_ads_removed';
  // Anlam değişti: artık "bir kez gösterildi" değil, "kullanıcı "kapattım,
  // gösterme" dedi". Eski kirli değeri yok saymak için yeni anahtar.
  static const _reachabilityHintKey = 'pucket_reachability_optout_v2';
  static const _botEasyCounterKey = 'pucket_bot_matches_since_easy';
  static const _langKey = 'pucket_language';

  AppLocalizations get l10n => AppLocalizations(language);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tutorialSeen = prefs.getBool(_tutorialKey) ?? false;
    firstMatchPlayed = prefs.getBool(_firstMatchKey) ?? false;
    adsRemoved = prefs.getBool(_adsRemovedKey) ?? false;
    reachabilityHintShown = prefs.getBool(_reachabilityHintKey) ?? false;
    botMatchesSinceEasy = prefs.getInt(_botEasyCounterKey) ?? 0;
    final savedLang = prefs.getString(_langKey);
    if (savedLang != null) {
      language = AppLanguage.fromCode(savedLang);
    } else {
      language = AppLanguage.fromDeviceLocale();
      await prefs.setString(_langKey, language.code);
    }
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

  Future<void> markFirstMatchPlayed() async {
    if (firstMatchPlayed) return;
    firstMatchPlayed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstMatchKey, true);
  }

  Future<void> markReachabilityHintShown() async {
    if (reachabilityHintShown) return;
    reachabilityHintShown = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reachabilityHintKey, true);
  }

  Future<void> setBotMatchesSinceEasy(int value) async {
    botMatchesSinceEasy = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_botEasyCounterKey, value);
  }

  Future<void> setAdsRemoved(bool value) async {
    adsRemoved = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adsRemovedKey, value);
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      '${musicOn ? 1 : 0}|${sfxOn ? 1 : 0}|${vibrationOn ? 1 : 0}|$musicVolume|$sfxVolume',
    );
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (language == lang) return;
    language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, lang.code);
    notifyListeners();
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
