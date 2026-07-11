import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'game/game_controller.dart';
import 'config/ad_config.dart';
import 'l10n/app_language.dart';
import 'screens/auth_screen.dart';
import 'screens/brand_splash.dart';
import 'screens/offline_gate.dart';
import 'screens/menu_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/username_screen.dart';
import 'services/ad_service.dart';
import 'services/consent_service.dart';
import 'services/api_config.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/career_service.dart';
import 'services/firebase_engagement_service.dart';
import 'services/firebase_init.dart';
import 'services/settings_service.dart';
import 'services/deep_link_service.dart';
import 'services/deep_link_listener.dart';
import 'services/disc_image_cache.dart';
import 'services/battle_pass_api.dart';
import 'services/meta_api.dart';
import 'services/player_meta_service.dart';
import 'services/purchase_service.dart';
import 'services/firebase_messaging_background.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';
import 'widgets/pucket_logo.dart';
import 'widgets/yesa_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));

  // Hızlı: yerel ayarlar + önbellek oturum
  final settings = SettingsService();
  final auth = AuthService();
  final career = CareerService();
  await Future.wait([
    settings.load(),
    auth.loadLocalCache(),
    career.load(),
  ]);

  await initFirebaseIfConfigured();
  if (firebaseEnabled) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(PushService.setup());
    unawaited(FirebaseEngagementService.init());
  }

  await auth.initFirebase();

  final playerMeta = PlayerMetaService();
  final audio = AudioService(settings);
  final ads = AdService();
  ads.adsRemoved = settings.adsRemoved;
  final purchases = PurchaseService();
  purchases.onPurchased = (productId) {
    _handlePurchase(productId, settings, ads, auth, playerMeta);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: career),
        ChangeNotifierProvider.value(value: playerMeta),
        ChangeNotifierProvider.value(value: audio),
        ChangeNotifierProvider.value(value: ads),
        ChangeNotifierProvider.value(value: purchases),
        ChangeNotifierProvider(
          create: (ctx) => GameController(
            ctx.read<SettingsService>(),
            wsUrl: kWsServerUrl,
            auth: ctx.read<AuthService>(),
            audio: ctx.read<AudioService>(),
          ),
        ),
      ],
      child: const RootApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_warmUpDeferred(ads));
    unawaited(purchases.init());
  });
}

/// Satın alma tamamlanınca ödülü uygula.
void _handlePurchase(
  String productId,
  SettingsService settings,
  AdService ads,
  AuthService auth,
  PlayerMetaService meta,
) {
  switch (productId) {
    case ProductIds.removeAds:
      ads.adsRemoved = true;
      unawaited(settings.setAdsRemoved(true));
      break;
    case ProductIds.tokens100:
      unawaited(MetaApi.grantIapTokens(auth.getUid(), 100).then((_) => meta.load(auth.getUid())));
      break;
    case ProductIds.tokens500:
      unawaited(MetaApi.grantIapTokens(auth.getUid(), 550).then((_) => meta.load(auth.getUid())));
      break;
    case ProductIds.tokens1200:
      unawaited(MetaApi.grantIapTokens(auth.getUid(), 1200).then((_) => meta.load(auth.getUid())));
      break;
    case ProductIds.vip:
      // VIP: reklamsız + sunucuda vip bayrağı (+%50 jeton) + özel pul.
      ads.adsRemoved = true;
      unawaited(settings.setAdsRemoved(true));
      unawaited(MetaApi.unlockVip(auth.getUid()).then((_) => meta.load(auth.getUid())));
      break;
    case ProductIds.battlePassPremium:
      unawaited(BattlePassApi.unlockPremium(auth.getUid()));
      break;
  }
}

Future<void> _warmUpDeferred(AdService ads) async {
  if (AdConfig.supported) {
    // iOS: App Store zorunluluğu — reklam kişiselleştirme için ATT izni.
    // Kullanıcı reddetse de oyun ve reklamlar (kişiselleştirilmemiş) çalışır.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          // Splash animasyonunun üstüne binmesin diye kısa bekleme.
          await Future<void>.delayed(const Duration(milliseconds: 600));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (_) {}
    }
    await ConsentService.ensureConsent();
    await ads.init();
  }
  unawaited(DiscImageCache.preload());
}

/// Açılışta bir kez Yesa Studio marka ekranını gösterir, sonra oyuna geçer.
class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _showBrand = true;

  @override
  void initState() {
    super.initState();
    // İnternet kontrolünü marka animasyonu sırasında önden başlat.
    OfflineGate.prewarm();
  }

  @override
  Widget build(BuildContext context) {
    if (_showBrand) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BrandSplash(onDone: () {
          if (mounted) setState(() => _showBrand = false);
        }),
      );
    }
    // İnternet yoksa oyuna sokma — bağlanınca kendiliğinden devam eder.
    return const OfflineGate(child: PucketApp());
  }
}

class PucketApp extends StatelessWidget {
  const PucketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, SettingsService>(
      builder: (context, auth, settings, _) {
        final Widget home;
        switch (auth.authState) {
          case AuthState.loading:
            home = const _Splash();
          case AuthState.needsUsername:
            home = const UsernameScreen();
          case AuthState.authenticated:
            home = const _AuthenticatedHome();
          case AuthState.unauthenticated:
            home = const AuthScreen();
        }

        return DeepLinkListener(
          child: MaterialApp(
          title: 'PUCKET',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: settings.language.locale,
          supportedLocales: AppLanguage.values.map((l) => l.locale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            return Directionality(
              textDirection: settings.language.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: ColoredBox(
                color: AppColors.bg,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    // BlueStacks / geniş ekran: içeriği ortala, arka plan tüm alanı kaplasın
                    if (w > h * 0.72) {
                      final phoneWidth = (h * 0.56).clamp(280.0, 420.0);
                      return Center(
                        child: SizedBox(
                          width: phoneWidth,
                          height: h,
                          child: content,
                        ),
                      );
                    }
                    return content;
                  },
                ),
              ),
            );
          },
          home: home,
        ),
        );
      },
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome();

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootAuthenticated());
  }

  Future<void> _bootAuthenticated() async {
    if (!mounted) return;

    // Menüyü hemen göster — ağ istekleri arkada
    setState(() => _tutorialChecked = true);

    final settings = context.read<SettingsService>();
    final auth = context.read<AuthService>();
    final career = context.read<CareerService>();
    final meta = context.read<PlayerMetaService>();
    final audio = context.read<AudioService>();

    unawaited(audio.playMenuMusic());
    unawaited(meta.load(auth.getUid(), name: auth.getName()));
    unawaited(career.syncFromCloud(auth.getUid()));
    unawaited(PushService.initAndRegister(auth.getUid()));
    unawaited(FirebaseEngagementService.setUser(auth.getUid()));
    unawaited(FirebaseEngagementService.logScreen('menu'));

    if (mounted) DeepLinkService.consumePending(context);

    if (!settings.tutorialSeen && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TutorialScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_tutorialChecked) {
      return const _Splash();
    }
    return const MenuScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: YesaBackground(
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PucketLogo(height: 160, showTagline: true),
              SizedBox(height: 28),
              CircularProgressIndicator(color: AppColors.accentYellow),
            ],
          ),
        ),
      ),
    );
  }
}
