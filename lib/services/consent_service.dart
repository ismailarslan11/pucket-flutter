import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Google UMP — AB/UK reklam rızası (AdMob gereksinimi).
class ConsentService {
  ConsentService._();

  static bool _updateFinished = false;

  static bool get updateFinished => _updateFinished;

  static Future<void> ensureConsent() async {
    if (!AdConfig.supported) return;

    _updateFinished = false;
    final completer = Completer<void>();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      _updateFinished = true;
      if (!completer.isCompleted) completer.complete();
    }

    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) debugPrint('Consent form: $error');
          });
        } catch (e) {
          debugPrint('Consent form exception: $e');
        } finally {
          finish();
        }
      },
      (FormError error) {
        debugPrint('Consent info: $error');
        finish();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: finish,
    );
  }

  static Future<bool> canRequestAds() async {
    if (!AdConfig.supported) return false;
    try {
      return ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('canRequestAds error: $e');
      return false;
    }
  }

  static Future<void> showPrivacyOptions() async {
    if (!AdConfig.supported) return;
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Privacy options: $error');
    });
  }
}
