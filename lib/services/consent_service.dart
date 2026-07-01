import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Google UMP — AB/UK reklam rızası.
/// AdMob'da form yoksa (TR/sideload) UMP atlanır; reklamlar doğrudan yüklenir.
class ConsentService {
  ConsentService._();

  static bool _updateFinished = false;
  static bool _umpUnavailable = false;
  static String _lastError = '';

  static bool get updateFinished => _updateFinished;
  static bool get umpUnavailable => _umpUnavailable;
  static String get lastError => _lastError;

  static bool _isMisconfiguration(String msg) {
    final m = msg.toLowerCase();
    return m.contains('misconfiguration') ||
        m.contains('no form') ||
        m.contains('failed to read publisher');
  }

  static Future<void> ensureConsent() async {
    if (!AdConfig.supported || _umpUnavailable) {
      _updateFinished = true;
      return;
    }

    _updateFinished = false;
    _lastError = '';
    final completer = Completer<void>();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      _updateFinished = true;
      if (!completer.isCompleted) completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          final formAvailable = await ConsentInformation.instance.isConsentFormAvailable();
          if (!formAvailable) {
            finish();
            return;
          }
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error == null) return;
            if (_isMisconfiguration(error.message)) {
              _umpUnavailable = true;
              _lastError = '';
            } else {
              _lastError = error.message;
            }
            debugPrint('Consent form: $error');
          });
        } catch (e) {
          final msg = e.toString();
          if (_isMisconfiguration(msg)) {
            _umpUnavailable = true;
            _lastError = '';
          } else {
            _lastError = msg;
          }
          debugPrint('Consent form exception: $e');
        } finally {
          finish();
        }
      },
      (FormError error) {
        if (_isMisconfiguration(error.message)) {
          _umpUnavailable = true;
          _lastError = '';
        } else {
          _lastError = error.message;
        }
        debugPrint('Consent info: $error');
        finish();
      },
    );

    await completer.future.timeout(const Duration(seconds: 5), onTimeout: finish);
  }

  static Future<bool> canRequestAds() async {
    if (!AdConfig.supported) return false;
    if (_umpUnavailable) return true;
    try {
      return ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('canRequestAds error: $e');
      return true;
    }
  }

  static Future<bool> shouldRequestAds() async {
    if (!AdConfig.supported) return false;
    if (_umpUnavailable) return true;
    if (await canRequestAds()) return true;

    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.notRequired || status == ConsentStatus.obtained) {
        return true;
      }
      if (status == ConsentStatus.unknown && _updateFinished) return true;
      if (status == ConsentStatus.required) return false;
    } catch (e) {
      debugPrint('shouldRequestAds error: $e');
    }
    return true;
  }

  static Future<String> debugSummary() async {
    if (!AdConfig.supported) return 'Platform desteklenmiyor';
    if (_umpUnavailable) return 'UMP kapalı (AdMob formu yok — TR için normal)';
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      final can = await ConsentInformation.instance.canRequestAds();
      final should = await shouldRequestAds();
      var s = 'rıza=$status · canRequest=$can · yükle=$should';
      if (_lastError.isNotEmpty) s += ' · $_lastError';
      return s;
    } catch (e) {
      return 'UMP okunamadı: $e';
    }
  }

  static Future<bool> showPrivacyOptions() async {
    if (!AdConfig.supported) return false;
    if (_umpUnavailable) return false;
    var ok = true;
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        ok = false;
        if (_isMisconfiguration(error.message)) {
          _umpUnavailable = true;
          _lastError = '';
        }
        debugPrint('Privacy options: $error');
      }
    });
    return ok;
  }
}
