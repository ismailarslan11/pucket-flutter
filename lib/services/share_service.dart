import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareMatchResult({
    required String playerName,
    required bool won,
    required String score,
    int? eloChange,
    int? newElo,
    String? league,
  }) async {
    final result = won ? 'Kazandım' : 'Kaybettim';
    final eloPart = eloChange != null
        ? '\n${eloChange >= 0 ? '+' : ''}$eloChange ELO → ${newElo ?? ''} ($league)'
        : '';
    await SharePlus.instance.share(ShareParams(text:
      'PUCKET\n$playerName — $result ($score)$eloPart\n\nSen de PUCKET indir, bana meydan oku!',
    ));
  }

  static Future<void> shareRoomInvite(String roomCode) async {
    await SharePlus.instance.share(ShareParams(text:
      'PUCKET\'ta seni bekliyorum!\nOda kodu: $roomCode\n\nPUCKET\'i aç → Odaya Katıl → kodu gir. '
      'Telefonunda kuruluysa direkt katıl: pucket://join/$roomCode',
    ));
  }

  static Future<void> shareInviteLink() async {
    await SharePlus.instance.share(ShareParams(text:
      'PUCKET — online pul fırlatma düellosu!\nİndir, bana meydan oku.',
    ));
  }
}
