import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Google UMP — AB/UK reklam rızası (AdMob gereksinimi).
class ConsentService {
  ConsentService._();

  static Future<void> ensureConsent() async {
    if (!AdConfig.supported) return;

    final completer = Completer<void>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) debugPrint('Consent form: $error');
          });
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint('Consent info: $error');
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    );
  }

  static Future<bool> canRequestAds() async {
    if (!AdConfig.supported) return false;
    return ConsentInformation.instance.canRequestAds();
  }

  static Future<void> showPrivacyOptions() async {
    if (!AdConfig.supported) return;
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) debugPrint('Privacy options: $error');
    });
  }
}
