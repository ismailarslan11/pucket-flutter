import '../models/rank_tier.dart';
import 'app_language.dart';

class AppLocalizations {
  AppLocalizations(this.lang);

  final AppLanguage lang;

  String _t(String key) =>
      _all[lang.code]?[key] ?? _all[AppLanguage.tr.code]![key] ?? key;

  // ── Common ──
  String get ok => _t('ok');
  String get back => _t('back');
  String get save => _t('save');
  String get saveAndBack => _t('saveAndBack');
  String get menu => _t('menu');
  String get or => _t('or');
  String get more => _t('more');
  String get onlineMultiplayer => _t('onlineMultiplayer');
  String get winsLosses => _t('winsLosses');
  String get yes => _t('yes');
  String get no => _t('no');

  // ── Menu ──
  String get menuRanked => _t('menuRanked');
  String get menuQuick => _t('menuQuick');
  String get menuCreateRoom => _t('menuCreateRoom');
  String get menuJoinRoom => _t('menuJoinRoom');
  String get menuCareer => _t('menuCareer');
  String get menuVsBot => _t('menuVsBot');
  String get menuLeaderboard => _t('menuLeaderboard');
  String get menuTutorial => _t('menuTutorial');
  String get menuProfile => _t('menuProfile');
  String get menuSettings => _t('menuSettings');
  String careerSubtitle(int kp, String league) => _t('careerSubtitle').replaceAll('{kp}', '$kp').replaceAll('{league}', league);

  // ── Settings ──
  String get settingsTitle => _t('settingsTitle');
  String get settingsLanguage => _t('settingsLanguage');
  String get settingsLanguageSub => _t('settingsLanguageSub');
  String get settingsMusic => _t('settingsMusic');
  String get settingsMusicSub => _t('settingsMusicSub');
  String get settingsSfx => _t('settingsSfx');
  String get settingsSfxSub => _t('settingsSfxSub');
  String get settingsMusicVol => _t('settingsMusicVol');
  String get settingsSfxVol => _t('settingsSfxVol');
  String get settingsVibration => _t('settingsVibration');
  String get settingsVibrationSub => _t('settingsVibrationSub');
  String get settingsAds => _t('settingsAds');
  String get settingsAdsSub => _t('settingsAdsSub');
  String get privacyPolicy => _t('privacyPolicy');
  String get termsOfUse => _t('termsOfUse');
  String get botDifficulty => _t('botDifficulty');

  // ── Auth ──
  String get authContinueLogin => _t('authContinueLogin');
  String get authGoogle => _t('authGoogle');
  String get authGuest => _t('authGuest');
  String get authGoogleHint => _t('authGoogleHint');
  String get authGoogleSetup => _t('authGoogleSetup');
  String get authGoogleNotConfigured => _t('authGoogleNotConfigured');
  String get authRankedHint => _t('authRankedHint');

  // ── Username ──
  String get usernameTitle => _t('usernameTitle');
  String get usernameGuestHint => _t('usernameGuestHint');
  String get usernameSetHint => _t('usernameSetHint');
  String get usernameHintChars => _t('usernameHintChars');
  String get usernameMin2 => _t('usernameMin2');
  String get usernameInvalidChars => _t('usernameInvalidChars');
  String get usernameChecking => _t('usernameChecking');
  String get usernameAvailable => _t('usernameAvailable');
  String get usernameTaken => _t('usernameTaken');
  String get usernameSubmit => _t('usernameSubmit');
  String get usernameSaving => _t('usernameSaving');
  String get usernameExample => _t('usernameExample');

  // ── Difficulty ──
  String get pickDifficulty => _t('pickDifficulty');
  String get youRedBotBlue => _t('youRedBotBlue');
  String get diffEasy => _t('diffEasy');
  String get diffEasySub => _t('diffEasySub');
  String get diffMedium => _t('diffMedium');
  String get diffMediumSub => _t('diffMediumSub');
  String get diffHard => _t('diffHard');
  String get diffHardSub => _t('diffHardSub');

  // ── Career ──
  String get careerTitle => _t('careerTitle');
  String get careerComplete => _t('careerComplete');
  String nextOpponent(String name, String league) =>
      _t('nextOpponent').replaceAll('{name}', name).replaceAll('{league}', league);
  String playWith(String name) => _t('playWith').replaceAll('{name}', name.toUpperCase());
  String get careerPoints => _t('careerPoints');
  String get replay => _t('replay');
  String get careerMode => _t('careerMode');
  String leagueLabel(String tierName) => _t('leagueLabel').replaceAll('{tier}', tierName);
  String promotedToLeague(String tierName) =>
      _t('promotedTo').replaceAll('{tier}', tierName.toUpperCase());
  String promotedLeagueMsg(String tierName) =>
      _t('promotedLeague').replaceAll('{tier}', tierName.toUpperCase());
  String get careerAllDone => _t('careerAllDone');
  String nextFight(String name) => _t('nextFight').replaceAll('{name}', name.toUpperCase());
  String get retry => _t('retry');
  String get playAgain => _t('playAgain');
  String get backToCareer => _t('backToCareer');
  String get kpAlreadyEarned => _t('kpAlreadyEarned');
  String opponentBeatYou(String name) => _t('opponentBeatYou').replaceAll('{name}', name);

  // ── Game ──
  String get youRed => _t('youRed');
  String get botBlue => _t('botBlue');
  String get botMode => _t('botMode');
  String get bot => _t('bot');
  String get ranked => _t('ranked');
  String get online => _t('online');
  String get blue => _t('blue');
  String get matchWon => _t('matchWon');
  String get matchLost => _t('matchLost');
  String get newMatch => _t('newMatch');
  String roundEnded(int n) => _t('roundEnded').replaceAll('{n}', '$n');
  String get roundWon => _t('roundWon');
  String get roundLost => _t('roundLost');
  String get nextRound => _t('nextRound');
  String get backToMenu => _t('backToMenu');
  String get reconnecting => _t('reconnecting');
  String opponentDisconnected(int sec) => _t('opponentDisconnected').replaceAll('{sec}', '$sec');
  String get opponentLeft => _t('opponentLeft');
  String get opponentLeftSub => _t('opponentLeftSub');
  String get rematchAsk => _t('rematchAsk');
  String get rematchAskSub => _t('rematchAskSub');
  String get rematchSent => _t('rematchSent');
  String get eloPoints => _t('eloPoints');
  String get paused => _t('paused');
  String get pausedByOpponent => _t('pausedByOpponent');
  String pauseWait(int sec) => _t('pauseWait').replaceAll('{sec}', '$sec');
  String pauseSelfMsg(int sec) => _t('pauseSelf').replaceAll('{sec}', '$sec');
  String get resume => _t('resume');
  String get restart => _t('restart');
  String get yourHalf => _t('yourHalf');
  String discsLeft(int n) => _t('discsLeft').replaceAll('{n}', '$n');
  String youAreTeam(String team) => _t('youAreTeam').replaceAll('{team}', team);
  String get teamRed => _t('teamRed');
  String get teamBlue => _t('teamBlue');
  String congrats(String score) => _t('congrats').replaceAll('{score}', score);
  String sorry(String score) => _t('sorry').replaceAll('{score}', score);

  // ── Tiers ──
  String tierName(RankTier tier) {
    switch (tier.minElo) {
      case 0:
        return tierBronze;
      case 1100:
        return tierSilver;
      case 1200:
        return tierGold;
      case 1350:
        return tierDiamond;
      case 1500:
        return tierMaster;
      default:
        return tierLegend;
    }
  }

  String get tierBronze => _t('tierBronze');
  String get tierSilver => _t('tierSilver');
  String get tierGold => _t('tierGold');
  String get tierDiamond => _t('tierDiamond');
  String get tierMaster => _t('tierMaster');
  String get tierLegend => _t('tierLegend');

  String difficultyLabel(String level) {
    switch (level) {
      case 'easy':
        return diffEasyShort;
      case 'hard':
        return diffHardShort;
      default:
        return diffMediumShort;
    }
  }

  String get diffEasyShort => _t('diffEasyShort');
  String get diffMediumShort => _t('diffMediumShort');
  String get diffHardShort => _t('diffHardShort');

  // ── Queue ──
  String get queueSearching => _t('queueSearching');
  String get queueSearchingElo => _t('queueSearchingElo');
  String get queueSearchingMatch => _t('queueSearchingMatch');
  String get queueFound => _t('queueFound');
  String get queueBotStarting => _t('queueBotStarting');
  String get queueRankedTitle => _t('queueRankedTitle');
  String get queueYourElo => _t('queueYourElo');
  String get queueLeave => _t('queueLeave');
  String get queueNoServer => _t('queueNoServer');
  String get queueCancel => _t('queueCancel');
  String get opponent => _t('opponent');
  String get youLabel => _t('youLabel');
  String get afkTitle => _t('afkTitle');
  String get afkSub => _t('afkSub');
  String get signOut => _t('signOut');

  // ── Extras ──
  String get menuTraining => _t('menuTraining');
  String get menuTournament => _t('menuTournament');
  String get menuCosmetics => _t('menuCosmetics');
  String get menuInvite => _t('menuInvite');
  String get dailyQuests => _t('dailyQuests');
  String get questPlay3 => _t('questPlay3');
  String get questWin1 => _t('questWin1');
  String get questCareer1 => _t('questCareer1');
  String get questClaim => _t('questClaim');
  String get questClaimed => _t('questClaimed');
  String get questInProgress => _t('questInProgress');
  String get trainingDesc => _t('trainingDesc');
  String get trainingShooting => _t('trainingShooting');
  String get trainingDefense => _t('trainingDefense');
  String get trainingFull => _t('trainingFull');
  String get trainingMode => _t('trainingMode');
  String get tournamentDesc => _t('tournamentDesc');
  String get tournamentJoin => _t('tournamentJoin');
  String get tournamentLeaderboard => _t('tournamentLeaderboard');
  String get tournamentEmpty => _t('tournamentEmpty');
  String get points => _t('points');
  String get cosmeticsDisc => _t('cosmeticsDisc');
  String get cosmeticsBoard => _t('cosmeticsBoard');
  String boardThemeName(String key) {
    switch (key) {
      case 'neon':
        return _t('boardThemeNeon');
      case 'wood':
        return _t('boardThemeWood');
      default:
        return _t('boardThemeClassic');
    }
  }

  String get shareResult => _t('shareResult');
  String get reportPlayer => _t('reportPlayer');
  String get reportSent => _t('reportSent');
  String get opponentProfile => _t('opponentProfile');
  String get profileTitle => _t('profileTitle');
  String get profileEmpty => _t('profileEmpty');
  String get matchHistory => _t('matchHistory');
  String get refresh => _t('refresh');
  String get noHistory => _t('noHistory');
  String get rankedLabel => _t('rankedLabel');
  String get casualLabel => _t('casualLabel');
  String get achievements => _t('achievements');
  String seasonLabel(String name) => _t('seasonLabel').replaceAll('{name}', name);
  String get seasonWins => _t('seasonWins');
  String get rankTitle => _t('rankTitle');
  String get rankAll => _t('rankAll');
  String get rankError => _t('rankError');
  String get rematch => _t('rematch');
  String get pauseRemaining => _t('pauseRemaining');

  static const _all = <String, Map<String, String>>{
    'tr': _tr,
    'en': _en,
    'de': _de,
    'es': _es,
    'ar': _ar,
    'fr': _fr,
  };
}

const _tr = {
  'ok': 'TAMAM',
  'back': 'GERİ',
  'save': 'KAYDET',
  'saveAndBack': 'KAYDET & GERİ',
  'menu': 'MENÜ',
  'or': 'veya',
  'more': 'daha fazla',
  'onlineMultiplayer': 'ONLINE MULTIPLAYER',
  'winsLosses': 'G',
  'yes': 'Evet',
  'no': 'Hayır',
  'menuRanked': '🏆 RANKED MAÇ',
  'menuQuick': '⚡ HIZLI EŞLEŞTİR',
  'menuCreateRoom': '🏠 ODA OLUŞTUR',
  'menuJoinRoom': '🔑 ODAYA KATIL',
  'menuCareer': '⚔ KARİYER MODU',
  'menuVsBot': '🤖 BİLGİSAYARA KARŞI',
  'menuLeaderboard': '🏅 SIRALAMALAR',
  'menuTutorial': 'NASIL OYNANIR?',
  'menuProfile': '👤 PROFİLİM',
  'menuSettings': '⚙ AYARLAR',
  'careerSubtitle': '{kp} KP · {league}',
  'settingsTitle': '⚙ AYARLAR',
  'settingsLanguage': 'Dil',
  'settingsLanguageSub': 'Uygulama dili',
  'settingsMusic': 'Müzik',
  'settingsMusicSub': 'Menü arkaplan müziği',
  'settingsSfx': 'Ses Efektleri',
  'settingsSfxSub': 'Fırlatma, çarpışma sesleri',
  'settingsMusicVol': 'Müzik Ses',
  'settingsSfxVol': 'Efekt Ses',
  'settingsVibration': 'Titreşim',
  'settingsVibrationSub': 'Atış ve kazanma titreşimi',
  'settingsAds': 'Reklamlar',
  'settingsAdsSub': 'Banner + maç arası reklamlar',
  'privacyPolicy': 'Gizlilik Politikası',
  'termsOfUse': 'Kullanım Şartları',
  'botDifficulty': 'Bot Zorluğu',
  'authContinueLogin': 'Devam etmek için giriş yap',
  'authGoogle': 'Google ile Giriş Yap',
  'authGuest': 'Misafir Olarak Devam Et',
  'authGoogleHint': 'Google ile giriş yaparak sıralama listesine katılır,\nilerlemen kaydedilir.',
  'authGoogleSetup': 'Google girişi için: bash tool/setup_firebase.sh',
  'authGoogleNotConfigured': 'Google girişi yapılandırılmamış — misafir olarak devam edebilirsin',
  'authRankedHint': 'Google ile giriş yaparak sıralama listesine katılır,\nilerlemen kaydedilir.',
  'usernameTitle': 'KULLANICI ADI',
  'usernameGuestHint': 'Misafir olarak devam — adın benzersiz olmalı',
  'usernameSetHint': 'Oyuncu adını belirle',
  'usernameHintChars': '2-16 karakter, harf ve rakam',
  'usernameMin2': 'En az 2 karakter',
  'usernameInvalidChars': 'Sadece harf, rakam ve _ kullanılabilir',
  'usernameChecking': 'Kontrol ediliyor...',
  'usernameAvailable': '✓ Bu ad müsait',
  'usernameTaken': '✗ Bu kullanıcı adı alınmış',
  'usernameSubmit': 'TAMAM →',
  'usernameSaving': 'KAYDEDİLİYOR...',
  'usernameExample': 'ör. PucketKing',
  'pickDifficulty': 'ZORLUK SEÇ',
  'youRedBotBlue': 'SEN 🔴 KIRMIZI · BOT 🔵 MAVİ',
  'diffEasy': '🟢 KOLAY',
  'diffEasySub': 'Yavaş · Az isabetli',
  'diffMedium': '🟡 ORTA',
  'diffMediumSub': 'Dengeli · Makul',
  'diffHard': '🔴 ZOR',
  'diffHardSub': 'Hızlı · İsabetli · Acımasız',
  'diffEasyShort': 'Kolay',
  'diffMediumShort': 'Orta',
  'diffHardShort': 'Zor',
  'careerTitle': 'KARİYER MODU',
  'careerComplete': '👑 Tüm rakipleri yendin — efsanesin!',
  'nextOpponent': 'Sıradaki: {name} ({league})',
  'playWith': '⚔ {name} İLE OYNA',
  'careerPoints': 'Kariyer Puanı (KP)',
  'replay': 'YENİDEN',
  'careerMode': 'KARİYER',
  'leagueLabel': '{tier} Ligi',
  'promotedTo': '🎉 {tier} LİGİNE YÜKSELDİN!',
  'careerAllDone': '👑 KARİYER TAMAMLANDI — TÜM RAKİPLER YENİLDİ!',
  'nextFight': '⚔ SIRADAKİ: {name}',
  'retry': '🔄 TEKRAR DENE',
  'playAgain': '↺ YENİDEN OYNA',
  'backToCareer': '📋 KARİYERE DÖN',
  'kpAlreadyEarned': 'Rakibi yeniden yendin — KP zaten alınmıştı',
  'opponentBeatYou': '{name} seni yendi — tekrar dene!',
  'youRed': 'SEN 🔴',
  'botBlue': 'BOT 🔵',
  'botMode': 'BOT MODU',
  'bot': 'BOT',
  'ranked': 'RANKED',
  'online': 'ONLINE',
  'blue': 'MAVİ',
  'matchWon': '🏆 MAÇ KAZANDIN!',
  'matchLost': '💀 MAÇ KAYBETTİN',
  'newMatch': 'YENİ MAÇ',
  'roundEnded': 'ROUND {n} BİTTİ',
  'roundWon': 'Round kazandın 🎉',
  'roundLost': 'Round kaybettin',
  'nextRound': 'SONRAKİ ROUND →',
  'backToMenu': 'MENÜYE DÖN',
  'reconnecting': 'Bağlantı yeniden kuruluyor...',
  'opponentDisconnected': 'Rakip bağlantısı koptu — {sec} sn bekleniyor',
  'opponentLeft': 'RAKİP AYRILDI',
  'opponentLeftSub': 'Bağlantı kesildi.',
  'rematchAsk': 'Tekrar oyna?',
  'rematchAskSub': 'Rakip yeni maç istiyor.',
  'rematchSent': 'Rematch isteği gönderildi — rakip onayı bekleniyor',
  'eloPoints': 'ELO puanı',
  'promotedLeague': '🎉 {tier} LİGİNE ÇIKTIN!',
  'paused': '⏸ DURAKLATILDI',
  'pausedByOpponent': '⏸ OYUN DURDURULDU',
  'pauseWait': 'Rakip oyunu durdurdu.\nEn fazla {sec} saniye beklenir.',
  'pauseSelf': 'Oyun duraklatıldı.\nEn fazla {sec} saniye.',
  'resume': '▶ DEVAM ET',
  'restart': '↺ YENİDEN BAŞLA',
  'yourHalf': 'SENİN YARINDA',
  'discsLeft': '{n} pul',
  'youAreTeam': 'SEN → {team}',
  'teamRed': '🔴 Kırmızı',
  'teamBlue': '🔵 Mavi',
  'congrats': 'Tebrikler! {score}',
  'sorry': 'Maalesef... {score}',
  'tierBronze': 'Bronz',
  'tierSilver': 'Gümüş',
  'tierGold': 'Altın',
  'tierDiamond': 'Elmas',
  'tierMaster': 'Usta',
  'tierLegend': 'Efsane',
  'queueSearching': 'Rakip aranıyor...',
  'queueSearchingElo': 'ELO seviyenizde rakip aranıyor...',
  'queueSearchingMatch': 'Eşleştirme kuruluyor...',
  'queueFound': 'Rakip bulundu!',
  'queueBotStarting': 'Rakip bulundu! Başlıyor...',
  'queueRankedTitle': '🏆 RANKED MAÇ',
  'queueYourElo': 'ELO PUANINIZ',
  'queueLeave': 'KUYRUKTAN ÇIK',
  'queueNoServer': 'Sunucu yok — bot moduna geçiliyor',
  'queueCancel': 'İPTAL',
  'opponent': 'Rakip',
  'youLabel': 'SEN',
  'afkTitle': 'AFK',
  'afkSub': 'Uzun süre hamle yapmadınız — maç sonlandırıldı.',
  'signOut': 'Çıkış Yap',
  'menuTraining': '🏋️ ANTRENMAN',
  'menuTournament': '🏆 HAFTALIK KUPA',
  'menuCosmetics': '🎨 KOZMETİK',
  'menuInvite': '📤 ARKADAŞ DAVET',
  'dailyQuests': 'Günlük Görevler',
  'questPlay3': '3 maç oyna',
  'questWin1': '1 maç kazan',
  'questCareer1': '1 kariyer galibiyeti',
  'questClaim': 'ÖDÜLÜ AL (+50 KP)',
  'questClaimed': 'Ödül alındı',
  'questInProgress': 'Görevler devam ediyor',
  'trainingDesc': 'Tek disk veya bot ile pratik yap. ELO etkilenmez.',
  'trainingShooting': '🎯 Atış Pratiği',
  'trainingDefense': '🛡 Savunma Pratiği',
  'trainingFull': '⚔ Tam Antrenman Maçı',
  'trainingMode': 'ANTRENMAN',
  'tournamentDesc': 'Haftalık kupaya katıl, ranked galibiyetlerle puan kazan.',
  'tournamentJoin': 'TURNUVAYA KATIL',
  'tournamentLeaderboard': 'HAFTALIK SIRALAMA',
  'tournamentEmpty': 'Henüz katılımcı yok',
  'points': 'puan',
  'cosmeticsDisc': 'Disk rengi',
  'cosmeticsBoard': 'Tahta teması',
  'boardThemeClassic': 'Klasik',
  'boardThemeNeon': 'Neon',
  'boardThemeWood': 'Ahşap',
  'shareResult': 'PAYLAŞ',
  'reportPlayer': 'Raporla',
  'reportSent': 'Rapor gönderildi',
  'opponentProfile': 'Rakip',
  'profileTitle': 'PROFİL',
  'profileEmpty': 'Profil yok',
  'matchHistory': 'SON MAÇLAR',
  'refresh': 'YENİLE',
  'noHistory': 'Henüz maç geçmişi yok.\nRanked oyna veya sunucuya bağlan.',
  'rankedLabel': 'Ranked',
  'casualLabel': 'Casual',
  'achievements': 'BAŞARIMLAR',
  'seasonLabel': '{name}',
  'seasonWins': 'Sezon galibiyeti',
  'rankTitle': '🏅 SIRALAMALAR',
  'rankAll': 'Tümü',
  'rankError': 'Sıralama yüklenemedi',
  'rematch': 'TEKRAR OYNA',
  'pauseRemaining': 'Kalan: {sec} sn',
};

const _en = {
  'ok': 'OK',
  'back': 'BACK',
  'save': 'SAVE',
  'saveAndBack': 'SAVE & BACK',
  'menu': 'MENU',
  'or': 'or',
  'more': 'more',
  'onlineMultiplayer': 'ONLINE MULTIPLAYER',
  'winsLosses': 'W',
  'yes': 'Yes',
  'no': 'No',
  'menuRanked': '🏆 RANKED MATCH',
  'menuQuick': '⚡ QUICK MATCH',
  'menuCreateRoom': '🏠 CREATE ROOM',
  'menuJoinRoom': '🔑 JOIN ROOM',
  'menuCareer': '⚔ CAREER MODE',
  'menuVsBot': '🤖 VS COMPUTER',
  'menuLeaderboard': '🏅 LEADERBOARDS',
  'menuTutorial': 'HOW TO PLAY',
  'menuProfile': '👤 MY PROFILE',
  'menuSettings': '⚙ SETTINGS',
  'careerSubtitle': '{kp} CP · {league}',
  'settingsTitle': '⚙ SETTINGS',
  'settingsLanguage': 'Language',
  'settingsLanguageSub': 'App language',
  'settingsMusic': 'Music',
  'settingsMusicSub': 'Menu background music',
  'settingsSfx': 'Sound Effects',
  'settingsSfxSub': 'Shot and collision sounds',
  'settingsMusicVol': 'Music Volume',
  'settingsSfxVol': 'SFX Volume',
  'settingsVibration': 'Vibration',
  'settingsVibrationSub': 'Shot and win haptics',
  'settingsAds': 'Ads',
  'settingsAdsSub': 'Banner + between-match ads',
  'privacyPolicy': 'Privacy Policy',
  'termsOfUse': 'Terms of Use',
  'botDifficulty': 'Bot Difficulty',
  'authContinueLogin': 'Sign in to continue',
  'authGoogle': 'Sign in with Google',
  'authGuest': 'Continue as Guest',
  'authGoogleHint': 'Sign in with Google to join ranked\nand save your progress.',
  'authGoogleSetup': 'For Google sign-in: bash tool/setup_firebase.sh',
  'authGoogleNotConfigured': 'Google sign-in not configured — continue as guest',
  'authRankedHint': 'Sign in with Google to join ranked\nand save your progress.',
  'usernameTitle': 'USERNAME',
  'usernameGuestHint': 'Guest mode — pick a unique name',
  'usernameSetHint': 'Choose your player name',
  'usernameHintChars': '2-16 chars, letters and numbers',
  'usernameMin2': 'At least 2 characters',
  'usernameInvalidChars': 'Only letters, numbers and _ allowed',
  'usernameChecking': 'Checking...',
  'usernameAvailable': '✓ Name available',
  'usernameTaken': '✗ Username taken',
  'usernameSubmit': 'OK →',
  'usernameSaving': 'SAVING...',
  'usernameExample': 'e.g. PucketKing',
  'pickDifficulty': 'PICK DIFFICULTY',
  'youRedBotBlue': 'YOU 🔴 RED · BOT 🔵 BLUE',
  'diffEasy': '🟢 EASY',
  'diffEasySub': 'Slow · Low accuracy',
  'diffMedium': '🟡 MEDIUM',
  'diffMediumSub': 'Balanced · Fair',
  'diffHard': '🔴 HARD',
  'diffHardSub': 'Fast · Accurate · Ruthless',
  'diffEasyShort': 'Easy',
  'diffMediumShort': 'Medium',
  'diffHardShort': 'Hard',
  'careerTitle': 'CAREER MODE',
  'careerComplete': '👑 All rivals defeated — legendary!',
  'nextOpponent': 'Next: {name} ({league})',
  'playWith': '⚔ PLAY {name}',
  'careerPoints': 'Career Points (CP)',
  'replay': 'REPLAY',
  'careerMode': 'CAREER',
  'leagueLabel': '{tier} League',
  'promotedTo': '🎉 PROMOTED TO {tier}!',
  'careerAllDone': '👑 CAREER COMPLETE — ALL RIVALS BEATEN!',
  'nextFight': '⚔ NEXT: {name}',
  'retry': '🔄 RETRY',
  'playAgain': '↺ PLAY AGAIN',
  'backToCareer': '📋 BACK TO CAREER',
  'kpAlreadyEarned': 'Beat them again — CP already earned',
  'opponentBeatYou': '{name} beat you — try again!',
  'youRed': 'YOU 🔴',
  'botBlue': 'BOT 🔵',
  'botMode': 'BOT MODE',
  'bot': 'BOT',
  'ranked': 'RANKED',
  'online': 'ONLINE',
  'blue': 'BLUE',
  'matchWon': '🏆 YOU WON!',
  'matchLost': '💀 YOU LOST',
  'newMatch': 'NEW MATCH',
  'roundEnded': 'ROUND {n} OVER',
  'roundWon': 'Round won 🎉',
  'roundLost': 'Round lost',
  'nextRound': 'NEXT ROUND →',
  'backToMenu': 'BACK TO MENU',
  'reconnecting': 'Reconnecting...',
  'opponentDisconnected': 'Opponent disconnected — waiting {sec}s',
  'opponentLeft': 'OPPONENT LEFT',
  'opponentLeftSub': 'Connection lost.',
  'rematchAsk': 'Rematch?',
  'rematchAskSub': 'Opponent wants a new match.',
  'rematchSent': 'Rematch request sent — waiting for opponent',
  'eloPoints': 'ELO points',
  'promotedLeague': '🎉 PROMOTED TO {tier}!',
  'paused': '⏸ PAUSED',
  'pausedByOpponent': '⏸ GAME PAUSED',
  'pauseWait': 'Opponent paused.\nMax {sec} seconds wait.',
  'pauseSelf': 'Game paused.\nMax {sec} seconds.',
  'resume': '▶ RESUME',
  'restart': '↺ RESTART',
  'yourHalf': 'YOUR HALF',
  'discsLeft': '{n} discs',
  'youAreTeam': 'YOU → {team}',
  'teamRed': '🔴 Red',
  'teamBlue': '🔵 Blue',
  'congrats': 'Congrats! {score}',
  'sorry': 'Sorry... {score}',
  'tierBronze': 'Bronze',
  'tierSilver': 'Silver',
  'tierGold': 'Gold',
  'tierDiamond': 'Diamond',
  'tierMaster': 'Master',
  'tierLegend': 'Legend',
  'queueSearching': 'Searching for opponent...',
  'queueSearchingElo': 'Searching for opponent at your ELO...',
  'queueSearchingMatch': 'Matching players...',
  'queueFound': 'Opponent found!',
  'queueBotStarting': 'Opponent found! Starting...',
  'queueRankedTitle': '🏆 RANKED MATCH',
  'queueYourElo': 'YOUR ELO',
  'queueLeave': 'LEAVE QUEUE',
  'queueNoServer': 'No server — switching to bot mode',
  'queueCancel': 'CANCEL',
  'opponent': 'Opponent',
  'youLabel': 'YOU',
  'afkTitle': 'AFK',
  'afkSub': 'No move for too long — match ended.',
  'signOut': 'Sign Out',
  'menuTraining': '🏋️ TRAINING',
  'menuTournament': '🏆 WEEKLY CUP',
  'menuCosmetics': '🎨 COSMETICS',
  'menuInvite': '📤 INVITE FRIEND',
  'dailyQuests': 'Daily Quests',
  'questPlay3': 'Play 3 matches',
  'questWin1': 'Win 1 match',
  'questCareer1': '1 career win',
  'questClaim': 'CLAIM REWARD (+50 KP)',
  'questClaimed': 'Reward claimed',
  'questInProgress': 'Quests in progress',
  'trainingDesc': 'Practice with drills. ELO is not affected.',
  'trainingShooting': '🎯 Shooting Drill',
  'trainingDefense': '🛡 Defense Drill',
  'trainingFull': '⚔ Full Training Match',
  'trainingMode': 'TRAINING',
  'tournamentDesc': 'Join the weekly cup and earn points from ranked wins.',
  'tournamentJoin': 'JOIN TOURNAMENT',
  'tournamentLeaderboard': 'WEEKLY STANDINGS',
  'tournamentEmpty': 'No participants yet',
  'points': 'pts',
  'cosmeticsDisc': 'Disc color',
  'cosmeticsBoard': 'Board theme',
  'boardThemeClassic': 'Classic',
  'boardThemeNeon': 'Neon',
  'boardThemeWood': 'Wood',
  'shareResult': 'SHARE',
  'reportPlayer': 'Report',
  'reportSent': 'Report submitted',
  'opponentProfile': 'Opponent',
  'profileTitle': 'PROFILE',
  'profileEmpty': 'No profile',
  'matchHistory': 'RECENT MATCHES',
  'refresh': 'REFRESH',
  'noHistory': 'No match history yet.\nPlay ranked or connect to server.',
  'rankedLabel': 'Ranked',
  'casualLabel': 'Casual',
  'achievements': 'ACHIEVEMENTS',
  'seasonLabel': '{name}',
  'seasonWins': 'Season wins',
  'rankTitle': '🏅 LEADERBOARD',
  'rankAll': 'All',
  'rankError': 'Could not load leaderboard',
  'rematch': 'REMATCH',
  'pauseRemaining': 'Remaining: {sec}s',
};

const _de = {
  'ok': 'OK',
  'back': 'ZURÜCK',
  'save': 'SPEICHERN',
  'saveAndBack': 'SPEICHERN & ZURÜCK',
  'menu': 'MENÜ',
  'or': 'oder',
  'more': 'mehr',
  'onlineMultiplayer': 'ONLINE MULTIPLAYER',
  'winsLosses': 'S',
  'yes': 'Ja',
  'no': 'Nein',
  'menuRanked': '🏆 RANKED-MATCH',
  'menuQuick': '⚡ SCHNELLSUCHE',
  'menuCreateRoom': '🏠 RAUM ERSTELLEN',
  'menuJoinRoom': '🔑 RAUM BEITRETEN',
  'menuCareer': '⚔ KARRIEREMODUS',
  'menuVsBot': '🤖 GEGEN COMPUTER',
  'menuLeaderboard': '🏅 BESTENLISTE',
  'menuTutorial': 'SPIELANLEITUNG',
  'menuProfile': '👤 MEIN PROFIL',
  'menuSettings': '⚙ EINSTELLUNGEN',
  'careerSubtitle': '{kp} KP · {league}',
  'settingsTitle': '⚙ EINSTELLUNGEN',
  'settingsLanguage': 'Sprache',
  'settingsLanguageSub': 'App-Sprache',
  'settingsMusic': 'Musik',
  'settingsMusicSub': 'Menü-Hintergrundmusik',
  'settingsSfx': 'Soundeffekte',
  'settingsSfxSub': 'Schuss- und Kollisionsgeräusche',
  'settingsMusicVol': 'Musiklautstärke',
  'settingsSfxVol': 'Effektlautstärke',
  'settingsVibration': 'Vibration',
  'settingsVibrationSub': 'Haptik bei Schuss und Sieg',
  'settingsAds': 'Werbung',
  'settingsAdsSub': 'Banner + Werbung zwischen Matches',
  'privacyPolicy': 'Datenschutz',
  'termsOfUse': 'Nutzungsbedingungen',
  'botDifficulty': 'Bot-Schwierigkeit',
  'authContinueLogin': 'Zum Fortfahren anmelden',
  'authGoogle': 'Mit Google anmelden',
  'authGuest': 'Als Gast fortfahren',
  'authGoogleHint': 'Mit Google anmelden für Rangliste\nund gespeicherten Fortschritt.',
  'authGoogleSetup': 'Google-Anmeldung: bash tool/setup_firebase.sh',
  'authGoogleNotConfigured': 'Google nicht konfiguriert — als Gast fortfahren',
  'authRankedHint': 'Mit Google anmelden für Rangliste\nund gespeicherten Fortschritt.',
  'usernameTitle': 'BENUTZERNAME',
  'usernameGuestHint': 'Gastmodus — einzigartiger Name nötig',
  'usernameSetHint': 'Spielername wählen',
  'usernameHintChars': '2-16 Zeichen, Buchstaben und Zahlen',
  'usernameMin2': 'Mindestens 2 Zeichen',
  'usernameInvalidChars': 'Nur Buchstaben, Zahlen und _',
  'usernameChecking': 'Prüfen...',
  'usernameAvailable': '✓ Name verfügbar',
  'usernameTaken': '✗ Name vergeben',
  'usernameSubmit': 'OK →',
  'usernameSaving': 'SPEICHERN...',
  'usernameExample': 'z.B. PucketKing',
  'pickDifficulty': 'SCHWIERIGKEIT',
  'youRedBotBlue': 'DU 🔴 ROT · BOT 🔵 BLAU',
  'diffEasy': '🟢 LEICHT',
  'diffEasySub': 'Langsam · Ungenau',
  'diffMedium': '🟡 MITTEL',
  'diffMediumSub': 'Ausgewogen',
  'diffHard': '🔴 SCHWER',
  'diffHardSub': 'Schnell · Präzise · Hart',
  'diffEasyShort': 'Leicht',
  'diffMediumShort': 'Mittel',
  'diffHardShort': 'Schwer',
  'careerTitle': 'KARRIEREMODUS',
  'careerComplete': '👑 Alle Gegner besiegt!',
  'nextOpponent': 'Nächster: {name} ({league})',
  'playWith': '⚔ SPIELEN: {name}',
  'careerPoints': 'Karrierepunkte (KP)',
  'replay': 'NOCHMAL',
  'careerMode': 'KARRIERE',
  'leagueLabel': '{tier}-Liga',
  'promotedTo': '🎉 AUFSTIEG IN {tier}!',
  'careerAllDone': '👑 KARRIERE ABGESCHLOSSEN!',
  'nextFight': '⚔ NÄCHSTER: {name}',
  'retry': '🔄 ERNEUT',
  'playAgain': '↺ NOCHMAL',
  'backToCareer': '📋 ZUR KARRIERE',
  'kpAlreadyEarned': 'Schon besiegt — KP bereits erhalten',
  'opponentBeatYou': '{name} hat gewonnen — nochmal!',
  'youRed': 'DU 🔴',
  'botBlue': 'BOT 🔵',
  'botMode': 'BOT-MODUS',
  'bot': 'BOT',
  'ranked': 'RANKED',
  'online': 'ONLINE',
  'blue': 'BLAU',
  'matchWon': '🏆 GEWONNEN!',
  'matchLost': '💀 VERLOREN',
  'newMatch': 'NEUES MATCH',
  'roundEnded': 'RUNDE {n} BEENDET',
  'roundWon': 'Runde gewonnen 🎉',
  'roundLost': 'Runde verloren',
  'nextRound': 'NÄCHSTE RUNDE →',
  'backToMenu': 'ZUM MENÜ',
  'reconnecting': 'Verbindung wird wiederhergestellt...',
  'opponentDisconnected': 'Gegner offline — warte {sec}s',
  'opponentLeft': 'GEGNER WEG',
  'opponentLeftSub': 'Verbindung getrennt.',
  'rematchAsk': 'Revanche?',
  'rematchAskSub': 'Gegner will ein neues Match.',
  'rematchSent': 'Revanche-Anfrage gesendet',
  'eloPoints': 'ELO-Punkte',
  'promotedLeague': '🎉 AUFSTIEG: {tier}!',
  'paused': '⏸ PAUSE',
  'pausedByOpponent': '⏸ SPIEL PAUSIERT',
  'pauseWait': 'Gegner pausiert.\nMax. {sec} Sekunden.',
  'pauseSelf': 'Spiel pausiert.\nMax. {sec} Sekunden.',
  'resume': '▶ WEITER',
  'restart': '↺ NEUSTART',
  'yourHalf': 'DEINE HÄLFTE',
  'discsLeft': '{n} Scheiben',
  'youAreTeam': 'DU → {team}',
  'teamRed': '🔴 Rot',
  'teamBlue': '🔵 Blau',
  'congrats': 'Glückwunsch! {score}',
  'sorry': 'Leider... {score}',
  'tierBronze': 'Bronze',
  'tierSilver': 'Silber',
  'tierGold': 'Gold',
  'tierDiamond': 'Diamant',
  'tierMaster': 'Meister',
  'tierLegend': 'Legende',
  'queueSearching': 'Gegner wird gesucht...',
  'queueSearchingElo': 'Gegner auf deinem ELO-Niveau...',
  'queueSearchingMatch': 'Spieler werden zusammengeführt...',
  'queueFound': 'Gegner gefunden!',
  'queueBotStarting': 'Gegner gefunden! Start...',
  'queueRankedTitle': '🏆 RANKED-MATCH',
  'queueYourElo': 'DEIN ELO',
  'queueLeave': 'WARTESCHLANGE VERLASSEN',
  'queueNoServer': 'Kein Server — Bot-Modus',
  'queueCancel': 'ABBRECHEN',
  'opponent': 'Gegner',
  'youLabel': 'DU',
  'afkTitle': 'AFK',
  'afkSub': 'Zu lange inaktiv — Match beendet.',
  'signOut': 'Abmelden',
  'menuTraining': '🏋️ TRAINING',
  'menuTournament': '🏆 WOCHENPOKAL',
  'menuCosmetics': '🎨 KOSMETIK',
  'menuInvite': '📤 FREUND EINLADEN',
  'dailyQuests': 'Tägliche Quests',
  'questPlay3': '3 Spiele spielen',
  'questWin1': '1 Spiel gewinnen',
  'questCareer1': '1 Karrieresieg',
  'questClaim': 'BELOHNUNG (+50 KP)',
  'questClaimed': 'Belohnt',
  'questInProgress': 'Quests laufen',
  'trainingDesc': 'Übe ohne ELO-Verlust.',
  'trainingShooting': '🎯 Schussübung',
  'trainingDefense': '🛡 Verteidigung',
  'trainingFull': '⚔ Trainingsspiel',
  'trainingMode': 'TRAINING',
  'tournamentDesc': 'Wöchentlicher Pokal — Punkte durch Ranked-Siege.',
  'tournamentJoin': 'TEILNEHMEN',
  'tournamentLeaderboard': 'WOCHENRANGLISTE',
  'tournamentEmpty': 'Noch keine Teilnehmer',
  'points': 'Pkt',
  'cosmeticsDisc': 'Scheibenfarbe',
  'cosmeticsBoard': 'Brett-Thema',
  'boardThemeClassic': 'Klassisch',
  'boardThemeNeon': 'Neon',
  'boardThemeWood': 'Holz',
  'shareResult': 'TEILEN',
  'reportPlayer': 'Melden',
  'reportSent': 'Meldung gesendet',
  'opponentProfile': 'Gegner',
  'profileTitle': 'PROFIL',
  'profileEmpty': 'Kein Profil',
  'matchHistory': 'LETZTE SPIELE',
  'refresh': 'AKTUALISIEREN',
  'noHistory': 'Noch keine Spiele.',
  'rankedLabel': 'Ranked',
  'casualLabel': 'Casual',
  'achievements': 'ERFOLGE',
  'seasonLabel': '{name}',
  'seasonWins': 'Saisonsiege',
  'rankTitle': '🏅 RANGLISTE',
  'rankAll': 'Alle',
  'rankError': 'Rangliste nicht geladen',
  'rematch': 'REVANCHE',
  'pauseRemaining': 'Verbleibend: {sec}s',
};

const _es = {
  'ok': 'OK',
  'back': 'ATRÁS',
  'save': 'GUARDAR',
  'saveAndBack': 'GUARDAR Y VOLVER',
  'menu': 'MENÚ',
  'or': 'o',
  'more': 'más',
  'onlineMultiplayer': 'MULTIJUGADOR ONLINE',
  'winsLosses': 'G',
  'yes': 'Sí',
  'no': 'No',
  'menuRanked': '🏆 PARTIDA RANKED',
  'menuQuick': '⚡ PARTIDA RÁPIDA',
  'menuCreateRoom': '🏠 CREAR SALA',
  'menuJoinRoom': '🔑 UNIRSE A SALA',
  'menuCareer': '⚔ MODO CARRERA',
  'menuVsBot': '🤖 VS ORDENADOR',
  'menuLeaderboard': '🏅 CLASIFICACIÓN',
  'menuTutorial': 'CÓMO JUGAR',
  'menuProfile': '👤 MI PERFIL',
  'menuSettings': '⚙ AJUSTES',
  'careerSubtitle': '{kp} PC · {league}',
  'settingsTitle': '⚙ AJUSTES',
  'settingsLanguage': 'Idioma',
  'settingsLanguageSub': 'Idioma de la app',
  'settingsMusic': 'Música',
  'settingsMusicSub': 'Música del menú',
  'settingsSfx': 'Efectos de sonido',
  'settingsSfxSub': 'Disparos y colisiones',
  'settingsMusicVol': 'Volumen música',
  'settingsSfxVol': 'Volumen efectos',
  'settingsVibration': 'Vibración',
  'settingsVibrationSub': 'Vibración al disparar',
  'settingsAds': 'Anuncios',
  'settingsAdsSub': 'Banner + anuncios entre partidas',
  'privacyPolicy': 'Política de privacidad',
  'termsOfUse': 'Términos de uso',
  'botDifficulty': 'Dificultad del bot',
  'authContinueLogin': 'Inicia sesión para continuar',
  'authGoogle': 'Iniciar con Google',
  'authGuest': 'Continuar como invitado',
  'authGoogleHint': 'Inicia con Google para ranked\ny guardar progreso.',
  'authGoogleSetup': 'Google: bash tool/setup_firebase.sh',
  'authGoogleNotConfigured': 'Google no configurado — continúa como invitado',
  'authRankedHint': 'Inicia con Google para ranked\ny guardar progreso.',
  'usernameTitle': 'NOMBRE DE USUARIO',
  'usernameGuestHint': 'Modo invitado — nombre único',
  'usernameSetHint': 'Elige tu nombre',
  'usernameHintChars': '2-16 caracteres, letras y números',
  'usernameMin2': 'Mínimo 2 caracteres',
  'usernameInvalidChars': 'Solo letras, números y _',
  'usernameChecking': 'Comprobando...',
  'usernameAvailable': '✓ Nombre disponible',
  'usernameTaken': '✗ Nombre ocupado',
  'usernameSubmit': 'OK →',
  'usernameSaving': 'GUARDANDO...',
  'usernameExample': 'ej. PucketKing',
  'pickDifficulty': 'ELIGE DIFICULTAD',
  'youRedBotBlue': 'TÚ 🔴 ROJO · BOT 🔵 AZUL',
  'diffEasy': '🟢 FÁCIL',
  'diffEasySub': 'Lento · Poca precisión',
  'diffMedium': '🟡 MEDIO',
  'diffMediumSub': 'Equilibrado',
  'diffHard': '🔴 DIFÍCIL',
  'diffHardSub': 'Rápido · Preciso · Duro',
  'diffEasyShort': 'Fácil',
  'diffMediumShort': 'Medio',
  'diffHardShort': 'Difícil',
  'careerTitle': 'MODO CARRERA',
  'careerComplete': '👑 ¡Todos los rivales vencidos!',
  'nextOpponent': 'Siguiente: {name} ({league})',
  'playWith': '⚔ JUGAR: {name}',
  'careerPoints': 'Puntos de carrera (PC)',
  'replay': 'REPETIR',
  'careerMode': 'CARRERA',
  'leagueLabel': 'Liga {tier}',
  'promotedTo': '🎉 ¡SUBISTE A {tier}!',
  'careerAllDone': '👑 ¡CARRERA COMPLETADA!',
  'nextFight': '⚔ SIGUIENTE: {name}',
  'retry': '🔄 REINTENTAR',
  'playAgain': '↺ JUGAR DE NUEVO',
  'backToCareer': '📋 VOLVER A CARRERA',
  'kpAlreadyEarned': 'Ya ganaste PC por este rival',
  'opponentBeatYou': '{name} te ganó — ¡intenta de nuevo!',
  'youRed': 'TÚ 🔴',
  'botBlue': 'BOT 🔵',
  'botMode': 'MODO BOT',
  'bot': 'BOT',
  'ranked': 'RANKED',
  'online': 'ONLINE',
  'blue': 'AZUL',
  'matchWon': '🏆 ¡GANASTE!',
  'matchLost': '💀 PERDISTE',
  'newMatch': 'NUEVA PARTIDA',
  'roundEnded': 'RONDA {n} TERMINADA',
  'roundWon': 'Ronda ganada 🎉',
  'roundLost': 'Ronda perdida',
  'nextRound': 'SIGUIENTE RONDA →',
  'backToMenu': 'AL MENÚ',
  'reconnecting': 'Reconectando...',
  'opponentDisconnected': 'Rival desconectado — espera {sec}s',
  'opponentLeft': 'RIVAL SE FUE',
  'opponentLeftSub': 'Conexión perdida.',
  'rematchAsk': '¿Revancha?',
  'rematchAskSub': 'El rival quiere otra partida.',
  'rematchSent': 'Solicitud de revancha enviada',
  'eloPoints': 'Puntos ELO',
  'promotedLeague': '🎉 ¡SUBISTE A {tier}!',
  'paused': '⏸ PAUSA',
  'pausedByOpponent': '⏸ JUEGO PAUSADO',
  'pauseWait': 'Rival pausó.\nMáx. {sec} segundos.',
  'pauseSelf': 'Juego pausado.\nMáx. {sec} segundos.',
  'resume': '▶ CONTINUAR',
  'restart': '↺ REINICIAR',
  'yourHalf': 'TU MITAD',
  'discsLeft': '{n} fichas',
  'youAreTeam': 'TÚ → {team}',
  'teamRed': '🔴 Rojo',
  'teamBlue': '🔵 Azul',
  'congrats': '¡Felicidades! {score}',
  'sorry': 'Lo siento... {score}',
  'tierBronze': 'Bronce',
  'tierSilver': 'Plata',
  'tierGold': 'Oro',
  'tierDiamond': 'Diamante',
  'tierMaster': 'Maestro',
  'tierLegend': 'Leyenda',
  'queueSearching': 'Buscando rival...',
  'queueSearchingElo': 'Buscando rival en tu ELO...',
  'queueSearchingMatch': 'Emparejando jugadores...',
  'queueFound': '¡Rival encontrado!',
  'queueBotStarting': '¡Rival encontrado! Iniciando...',
  'queueRankedTitle': '🏆 PARTIDA RANKED',
  'queueYourElo': 'TU ELO',
  'queueLeave': 'SALIR DE COLA',
  'queueNoServer': 'Sin servidor — modo bot',
  'queueCancel': 'CANCELAR',
  'opponent': 'Rival',
  'youLabel': 'TÚ',
  'afkTitle': 'AFK',
  'afkSub': 'Sin movimiento — partida terminada.',
  'signOut': 'Cerrar sesión',
  'menuTraining': '🏋️ ENTRENAMIENTO',
  'menuTournament': '🏆 COPA SEMANAL',
  'menuCosmetics': '🎨 COSMÉTICOS',
  'menuInvite': '📤 INVITAR AMIGO',
  'dailyQuests': 'Misiones diarias',
  'questPlay3': 'Jugar 3 partidas',
  'questWin1': 'Ganar 1 partida',
  'questCareer1': '1 victoria carrera',
  'questClaim': 'RECLAMAR (+50 KP)',
  'questClaimed': 'Reclamado',
  'questInProgress': 'Misiones en curso',
  'trainingDesc': 'Practica sin afectar ELO.',
  'trainingShooting': '🎯 Tiro',
  'trainingDefense': '🛡 Defensa',
  'trainingFull': '⚔ Partido entrenamiento',
  'trainingMode': 'ENTRENAMIENTO',
  'tournamentDesc': 'Copa semanal — puntos por victorias ranked.',
  'tournamentJoin': 'UNIRSE',
  'tournamentLeaderboard': 'CLASIFICACIÓN',
  'tournamentEmpty': 'Sin participantes',
  'points': 'pts',
  'cosmeticsDisc': 'Color disco',
  'cosmeticsBoard': 'Tema tablero',
  'boardThemeClassic': 'Clásico',
  'boardThemeNeon': 'Neon',
  'boardThemeWood': 'Madera',
  'shareResult': 'COMPARTIR',
  'reportPlayer': 'Reportar',
  'reportSent': 'Reporte enviado',
  'opponentProfile': 'Rival',
  'profileTitle': 'PERFIL',
  'profileEmpty': 'Sin perfil',
  'matchHistory': 'PARTIDAS RECIENTES',
  'refresh': 'ACTUALIZAR',
  'noHistory': 'Sin historial aún.',
  'rankedLabel': 'Ranked',
  'casualLabel': 'Casual',
  'achievements': 'LOGROS',
  'seasonLabel': '{name}',
  'seasonWins': 'Victorias temporada',
  'rankTitle': '🏅 CLASIFICACIÓN',
  'rankAll': 'Todos',
  'rankError': 'Error al cargar',
  'rematch': 'REVANCHA',
  'pauseRemaining': 'Quedan: {sec}s',
};

const _ar = {
  'ok': 'موافق',
  'back': 'رجوع',
  'save': 'حفظ',
  'saveAndBack': 'حفظ ورجوع',
  'menu': 'القائمة',
  'or': 'أو',
  'more': 'المزيد',
  'onlineMultiplayer': 'MULTIPLAYER ONLINE',
  'winsLosses': 'ف',
  'yes': 'نعم',
  'no': 'لا',
  'menuRanked': '🏆 مباراة مصنّفة',
  'menuQuick': '⚡ مباراة سريعة',
  'menuCreateRoom': '🏠 إنشاء غرفة',
  'menuJoinRoom': '🔑 الانضمام لغرفة',
  'menuCareer': '⚔ وضع المسيرة',
  'menuVsBot': '🤖 ضد الكمبيوتر',
  'menuLeaderboard': '🏅 المتصدرون',
  'menuTutorial': 'كيفية اللعب',
  'menuProfile': '👤 ملفي',
  'menuSettings': '⚙ الإعدادات',
  'careerSubtitle': '{kp} نقطة · {league}',
  'settingsTitle': '⚙ الإعدادات',
  'settingsLanguage': 'اللغة',
  'settingsLanguageSub': 'لغة التطبيق',
  'settingsMusic': 'الموسيقى',
  'settingsMusicSub': 'موسيقى القائمة',
  'settingsSfx': 'المؤثرات',
  'settingsSfxSub': 'أصوات الرمي والتصادم',
  'settingsMusicVol': 'صوت الموسيقى',
  'settingsSfxVol': 'صوت المؤثرات',
  'settingsVibration': 'الاهتزاز',
  'settingsVibrationSub': 'اهتزاز عند الرمي والفوز',
  'settingsAds': 'الإعلانات',
  'settingsAdsSub': 'بانر + إعلانات بين المباريات',
  'privacyPolicy': 'سياسة الخصوصية',
  'termsOfUse': 'شروط الاستخدام',
  'botDifficulty': 'صعوبة البوت',
  'authContinueLogin': 'سجّل الدخول للمتابعة',
  'authGoogle': 'الدخول عبر Google',
  'authGuest': 'المتابعة كضيف',
  'authGoogleHint': 'سجّل عبر Google للانضمام للتصنيف\nوحفظ تقدمك.',
  'authGoogleSetup': 'Google: bash tool/setup_firebase.sh',
  'authGoogleNotConfigured': 'Google غير مهيأ — تابع كضيف',
  'authRankedHint': 'سجّل عبر Google للانضمام للتصنيف\nوحفظ تقدمك.',
  'usernameTitle': 'اسم المستخدم',
  'usernameGuestHint': 'وضع الضيف — اسم فريد مطلوب',
  'usernameSetHint': 'اختر اسم اللاعب',
  'usernameHintChars': '2-16 حرفاً وأرقاماً',
  'usernameMin2': 'حرفان على الأقل',
  'usernameInvalidChars': 'حروف وأرقام و _ فقط',
  'usernameChecking': 'جاري التحقق...',
  'usernameAvailable': '✓ الاسم متاح',
  'usernameTaken': '✗ الاسم مأخوذ',
  'usernameSubmit': 'موافق →',
  'usernameSaving': 'جاري الحفظ...',
  'usernameExample': 'مثال PucketKing',
  'pickDifficulty': 'اختر الصعوبة',
  'youRedBotBlue': 'أنت 🔴 أحمر · بوت 🔵 أزرق',
  'diffEasy': '🟢 سهل',
  'diffEasySub': 'بطيء · دقة منخفضة',
  'diffMedium': '🟡 متوسط',
  'diffMediumSub': 'متوازن',
  'diffHard': '🔴 صعب',
  'diffHardSub': 'سريع · دقيق · قاسٍ',
  'diffEasyShort': 'سهل',
  'diffMediumShort': 'متوسط',
  'diffHardShort': 'صعب',
  'careerTitle': 'وضع المسيرة',
  'careerComplete': '👑 هزمت كل الخصوم!',
  'nextOpponent': 'التالي: {name} ({league})',
  'playWith': '⚔ العب ضد {name}',
  'careerPoints': 'نقاط المسيرة',
  'replay': 'إعادة',
  'careerMode': 'مسيرة',
  'leagueLabel': 'دوري {tier}',
  'promotedTo': '🎉 صعدت إلى {tier}!',
  'careerAllDone': '👑 اكتملت المسيرة!',
  'nextFight': '⚔ التالي: {name}',
  'retry': '🔄 أعد المحاولة',
  'playAgain': '↺ العب مجدداً',
  'backToCareer': '📋 العودة للمسيرة',
  'kpAlreadyEarned': 'سبق أن حصلت على النقاط',
  'opponentBeatYou': '{name} هزمك — حاول مجدداً!',
  'youRed': 'أنت 🔴',
  'botBlue': 'بوت 🔵',
  'botMode': 'وضع البوت',
  'bot': 'بوت',
  'ranked': 'RANKED',
  'online': 'ONLINE',
  'blue': 'أزرق',
  'matchWon': '🏆 فزت!',
  'matchLost': '💀 خسرت',
  'newMatch': 'مباراة جديدة',
  'roundEnded': 'انتهت الجولة {n}',
  'roundWon': 'فزت بالجولة 🎉',
  'roundLost': 'خسرت الجولة',
  'nextRound': 'الجولة التالية →',
  'backToMenu': 'القائمة',
  'reconnecting': 'إعادة الاتصال...',
  'opponentDisconnected': 'انقطع الخصم — انتظر {sec}ث',
  'opponentLeft': 'غادر الخصم',
  'opponentLeftSub': 'انقطع الاتصال.',
  'rematchAsk': 'إعادة اللعب؟',
  'rematchAskSub': 'الخصم يريد مباراة جديدة.',
  'rematchSent': 'تم إرسال طلب إعادة اللعب',
  'eloPoints': 'نقاط ELO',
  'promotedLeague': '🎉 صعدت إلى {tier}!',
  'paused': '⏸ متوقف',
  'pausedByOpponent': '⏸ توقف اللعب',
  'pauseWait': 'الخصم أوقف اللعب.\nبحد أقصى {sec} ثانية.',
  'pauseSelf': 'اللعب متوقف.\nبحد أقصى {sec} ثانية.',
  'resume': '▶ متابعة',
  'restart': '↺ إعادة',
  'yourHalf': 'نصفك',
  'discsLeft': '{n} قرص',
  'youAreTeam': 'أنت → {team}',
  'teamRed': '🔴 أحمر',
  'teamBlue': '🔵 أزرق',
  'congrats': 'أحسنت! {score}',
  'sorry': 'للأسف... {score}',
  'tierBronze': 'برونز',
  'tierSilver': 'فضة',
  'tierGold': 'ذهب',
  'tierDiamond': 'ماس',
  'tierMaster': 'أستاذ',
  'tierLegend': 'أسطورة',
  'queueSearching': 'البحث عن خصم...',
  'queueSearchingElo': 'البحث عن خصم بنفس ELO...',
  'queueSearchingMatch': 'جاري المطابقة...',
  'queueFound': 'تم العثور على خصم!',
  'queueBotStarting': 'تم العثور على خصم! بدء...',
  'queueRankedTitle': '🏆 مباراة مصنفة',
  'queueYourElo': 'نقاط ELO',
  'queueLeave': 'مغادرة الطابور',
  'queueNoServer': 'لا يوجد خادم — وضع البوت',
  'queueCancel': 'إلغاء',
  'opponent': 'الخصم',
  'youLabel': 'أنت',
  'afkTitle': 'AFK',
  'afkSub': 'بدون حركة لفترة طويلة — انتهت المباراة.',
  'signOut': 'تسجيل الخروج',
  'menuTraining': '🏋️ تدريب',
  'menuTournament': '🏆 كأس أسبوعي',
  'menuCosmetics': '🎨 مظهر',
  'menuInvite': '📤 دعوة صديق',
  'dailyQuests': 'مهام يومية',
  'questPlay3': 'العب 3 مباريات',
  'questWin1': 'اربح مباراة',
  'questCareer1': 'فوز مهنة واحد',
  'questClaim': 'استلام (+50 KP)',
  'questClaimed': 'تم الاستلام',
  'questInProgress': 'المهام جارية',
  'trainingDesc': 'تدرب بدون تأثير ELO.',
  'trainingShooting': '🎯 تدريب رمي',
  'trainingDefense': '🛡 دفاع',
  'trainingFull': '⚔ مباراة تدريب',
  'trainingMode': 'تدريب',
  'tournamentDesc': 'كأس أسبوعي — نقاط من فوز ranked.',
  'tournamentJoin': 'انضم',
  'tournamentLeaderboard': 'الترتيب',
  'tournamentEmpty': 'لا مشاركين',
  'points': 'نقطة',
  'cosmeticsDisc': 'لون القرص',
  'cosmeticsBoard': 'سمة اللوحة',
  'boardThemeClassic': 'كلاسيك',
  'boardThemeNeon': 'نيون',
  'boardThemeWood': 'خشب',
  'shareResult': 'مشاركة',
  'reportPlayer': 'إبلاغ',
  'reportSent': 'تم الإبلاغ',
  'opponentProfile': 'الخصم',
  'profileTitle': 'الملف',
  'profileEmpty': 'لا ملف',
  'matchHistory': 'آخر المباريات',
  'refresh': 'تحديث',
  'noHistory': 'لا سجل بعد.',
  'rankedLabel': 'Ranked',
  'casualLabel': 'Casual',
  'achievements': 'إنجازات',
  'seasonLabel': '{name}',
  'seasonWins': 'انتصارات الموسم',
  'rankTitle': '🏅 الترتيب',
  'rankAll': 'الكل',
  'rankError': 'فشل التحميل',
  'rematch': 'إعادة',
  'pauseRemaining': 'متبقي: {sec}ث',
};

const _fr = {
  'ok': 'OK',
  'back': 'RETOUR',
  'save': 'ENREGISTRER',
  'saveAndBack': 'ENREGISTRER & RETOUR',
  'menu': 'MENU',
  'or': 'ou',
  'more': 'plus',
  'onlineMultiplayer': 'MULTIJOUEUR EN LIGNE',
  'winsLosses': 'V',
  'yes': 'Oui',
  'no': 'Non',
  'menuRanked': '🏆 MATCH CLASSÉ',
  'menuQuick': '⚡ MATCH RAPIDE',
  'menuCreateRoom': '🏠 CRÉER SALON',
  'menuJoinRoom': '🔑 REJOINDRE SALON',
  'menuCareer': '⚔ MODE CARRIÈRE',
  'menuVsBot': '🤖 VS ORDINATEUR',
  'menuLeaderboard': '🏅 CLASSEMENT',
  'menuTutorial': 'COMMENT JOUER',
  'menuProfile': '👤 MON PROFIL',
  'menuSettings': '⚙ PARAMÈTRES',
  'careerSubtitle': '{kp} PC · {league}',
  'settingsTitle': '⚙ PARAMÈTRES',
  'settingsLanguage': 'Langue',
  'settingsLanguageSub': 'Langue de l\'app',
  'settingsMusic': 'Musique',
  'settingsMusicSub': 'Musique du menu',
  'settingsSfx': 'Effets sonores',
  'settingsSfxSub': 'Tirs et collisions',
  'settingsMusicVol': 'Volume musique',
  'settingsSfxVol': 'Volume effets',
  'settingsVibration': 'Vibration',
  'settingsVibrationSub': 'Vibration au tir et victoire',
  'settingsAds': 'Publicités',
  'settingsAdsSub': 'Bannière + pubs entre matchs',
  'privacyPolicy': 'Politique de confidentialité',
  'termsOfUse': 'Conditions d\'utilisation',
  'botDifficulty': 'Difficulté du bot',
  'authContinueLogin': 'Connectez-vous pour continuer',
  'authGoogle': 'Connexion Google',
  'authGuest': 'Continuer en invité',
  'authGoogleHint': 'Connectez-vous pour le classement\net sauvegarder votre progression.',
  'authGoogleSetup': 'Google : bash tool/setup_firebase.sh',
  'authGoogleNotConfigured': 'Google non configuré — continuez en invité',
  'authRankedHint': 'Connectez-vous pour le classement\net sauvegarder votre progression.',
  'usernameTitle': 'NOM D\'UTILISATEUR',
  'usernameGuestHint': 'Mode invité — nom unique requis',
  'usernameSetHint': 'Choisissez votre pseudo',
  'usernameHintChars': '2-16 caractères, lettres et chiffres',
  'usernameMin2': 'Au moins 2 caractères',
  'usernameInvalidChars': 'Lettres, chiffres et _ seulement',
  'usernameChecking': 'Vérification...',
  'usernameAvailable': '✓ Nom disponible',
  'usernameTaken': '✗ Nom pris',
  'usernameSubmit': 'OK →',
  'usernameSaving': 'ENREGISTREMENT...',
  'usernameExample': 'ex. PucketKing',
  'pickDifficulty': 'CHOISIR DIFFICULTÉ',
  'youRedBotBlue': 'VOUS 🔴 ROUGE · BOT 🔵 BLEU',
  'diffEasy': '🟢 FACILE',
  'diffEasySub': 'Lent · Peu précis',
  'diffMedium': '🟡 MOYEN',
  'diffMediumSub': 'Équilibré',
  'diffHard': '🔴 DIFFICILE',
  'diffHardSub': 'Rapide · Précis · Impitoyable',
  'diffEasyShort': 'Facile',
  'diffMediumShort': 'Moyen',
  'diffHardShort': 'Difficile',
  'careerTitle': 'MODE CARRIÈRE',
  'careerComplete': '👑 Tous les rivaux battus !',
  'nextOpponent': 'Suivant : {name} ({league})',
  'playWith': '⚔ JOUER : {name}',
  'careerPoints': 'Points carrière (PC)',
  'replay': 'REJOUER',
  'careerMode': 'CARRIÈRE',
  'leagueLabel': 'Ligue {tier}',
  'promotedTo': '🎉 PROMU EN {tier} !',
  'careerAllDone': '👑 CARRIÈRE TERMINÉE !',
  'nextFight': '⚔ SUIVANT : {name}',
  'retry': '🔄 RÉESSAYER',
  'playAgain': '↺ REJOUER',
  'backToCareer': '📋 RETOUR CARRIÈRE',
  'kpAlreadyEarned': 'Déjà vaincu — points déjà gagnés',
  'opponentBeatYou': '{name} vous a battu — réessayez !',
  'youRed': 'VOUS 🔴',
  'botBlue': 'BOT 🔵',
  'botMode': 'MODE BOT',
  'bot': 'BOT',
  'ranked': 'CLASSÉ',
  'online': 'EN LIGNE',
  'blue': 'BLEU',
  'matchWon': '🏆 VICTOIRE !',
  'matchLost': '💀 DÉFAITE',
  'newMatch': 'NOUVEAU MATCH',
  'roundEnded': 'MANCHE {n} TERMINÉE',
  'roundWon': 'Manche gagnée 🎉',
  'roundLost': 'Manche perdue',
  'nextRound': 'MANCHE SUIVANTE →',
  'backToMenu': 'AU MENU',
  'reconnecting': 'Reconnexion...',
  'opponentDisconnected': 'Adversaire déconnecté — {sec}s',
  'opponentLeft': 'ADVERSAIRE PARTI',
  'opponentLeftSub': 'Connexion perdue.',
  'rematchAsk': 'Revanche ?',
  'rematchAskSub': 'L\'adversaire veut rejouer.',
  'rematchSent': 'Demande de revanche envoyée',
  'eloPoints': 'Points ELO',
  'promotedLeague': '🎉 PROMU : {tier} !',
  'paused': '⏸ PAUSE',
  'pausedByOpponent': '⏸ JEU EN PAUSE',
  'pauseWait': 'Adversaire en pause.\nMax {sec} secondes.',
  'pauseSelf': 'Jeu en pause.\nMax {sec} secondes.',
  'resume': '▶ REPRENDRE',
  'restart': '↺ RECOMMENCER',
  'yourHalf': 'VOTRE MOITIÉ',
  'discsLeft': '{n} disques',
  'youAreTeam': 'VOUS → {team}',
  'teamRed': '🔴 Rouge',
  'teamBlue': '🔵 Bleu',
  'congrats': 'Bravo ! {score}',
  'sorry': 'Dommage... {score}',
  'tierBronze': 'Bronze',
  'tierSilver': 'Argent',
  'tierGold': 'Or',
  'tierDiamond': 'Diamant',
  'tierMaster': 'Maître',
  'tierLegend': 'Légende',
  'queueSearching': 'Recherche d\'adversaire...',
  'queueSearchingElo': 'Recherche à votre ELO...',
  'queueSearchingMatch': 'Appariement en cours...',
  'queueFound': 'Adversaire trouvé !',
  'queueBotStarting': 'Adversaire trouvé ! Démarrage...',
  'queueRankedTitle': '🏆 MATCH CLASSÉ',
  'queueYourElo': 'VOTRE ELO',
  'queueLeave': 'QUITTER LA FILE',
  'queueNoServer': 'Pas de serveur — mode bot',
  'queueCancel': 'ANNULER',
  'opponent': 'Adversaire',
  'youLabel': 'VOUS',
  'afkTitle': 'AFK',
  'afkSub': 'Inactivité prolongée — match terminé.',
  'signOut': 'Se déconnecter',
  'menuTraining': '🏋️ ENTRAÎNEMENT',
  'menuTournament': '🏆 COUPE HEBDO',
  'menuCosmetics': '🎨 COSMÉTIQUES',
  'menuInvite': '📤 INVITER',
  'dailyQuests': 'Quêtes quotidiennes',
  'questPlay3': 'Jouer 3 matchs',
  'questWin1': 'Gagner 1 match',
  'questCareer1': '1 victoire carrière',
  'questClaim': 'RÉCLAMER (+50 KP)',
  'questClaimed': 'Réclamé',
  'questInProgress': 'Quêtes en cours',
  'trainingDesc': 'Entraînez-vous sans ELO.',
  'trainingShooting': '🎯 Tir',
  'trainingDefense': '🛡 Défense',
  'trainingFull': '⚔ Match entraînement',
  'trainingMode': 'ENTRAÎNEMENT',
  'tournamentDesc': 'Coupe hebdo — points via ranked.',
  'tournamentJoin': 'REJOINDRE',
  'tournamentLeaderboard': 'CLASSEMENT',
  'tournamentEmpty': 'Aucun participant',
  'points': 'pts',
  'cosmeticsDisc': 'Couleur disque',
  'cosmeticsBoard': 'Thème plateau',
  'boardThemeClassic': 'Classique',
  'boardThemeNeon': 'Néon',
  'boardThemeWood': 'Bois',
  'shareResult': 'PARTAGER',
  'reportPlayer': 'Signaler',
  'reportSent': 'Signalement envoyé',
  'opponentProfile': 'Adversaire',
  'profileTitle': 'PROFIL',
  'profileEmpty': 'Pas de profil',
  'matchHistory': 'MATCHS RÉCENTS',
  'refresh': 'RAFRAÎCHIR',
  'noHistory': 'Pas encore d\'historique.',
  'rankedLabel': 'Ranked',
  'casualLabel': 'Casual',
  'achievements': 'SUCCÈS',
  'seasonLabel': '{name}',
  'seasonWins': 'Victoires saison',
  'rankTitle': '🏅 CLASSEMENT',
  'rankAll': 'Tous',
  'rankError': 'Erreur chargement',
  'rematch': 'REVANCHE',
  'pauseRemaining': 'Reste: {sec}s',
};
