import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'game/game_controller.dart';
import 'l10n/app_language.dart';
import 'screens/auth_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/username_screen.dart';
import 'services/ad_service.dart';
import 'services/api_config.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/career_service.dart';
import 'services/firebase_init.dart';
import 'services/settings_service.dart';
import 'services/deep_link_service.dart';
import 'services/player_meta_service.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initFirebaseIfConfigured();

  final settings = SettingsService();
  await settings.load();

  final auth = AuthService();
  await auth.loadLocalCache();
  await auth.initFirebase();

  final career = CareerService();
  await career.load();

  final playerMeta = PlayerMetaService();

  final audio = AudioService(settings);
  final ads = AdService();
  await ads.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: career),
        ChangeNotifierProvider.value(value: playerMeta),
        ChangeNotifierProvider.value(value: audio),
        ChangeNotifierProvider.value(value: ads),
        ChangeNotifierProvider(
          create: (ctx) => GameController(
            ctx.read<SettingsService>(),
            wsUrl: kWsServerUrl,
            auth: ctx.read<AuthService>(),
            audio: ctx.read<AudioService>(),
          ),
        ),
      ],
      child: const PucketApp(),
    ),
  );
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

        return MaterialApp(
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
                      final phoneWidth = h * 0.56;
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = context.read<SettingsService>();
      final auth = context.read<AuthService>();
      final career = context.read<CareerService>();
      final meta = context.read<PlayerMetaService>();
      final audio = context.read<AudioService>();
      await audio.playMenuMusic();
      await meta.load(auth.getUid());
      await career.syncFromCloud(auth.getUid());
      await PushService.initAndRegister(auth.getUid());
      if (mounted) DeepLinkService.consumePending(context);
      if (!settings.tutorialSeen && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TutorialScreen()),
        );
      }
      if (mounted) setState(() => _tutorialChecked = true);
    });
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
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PUCKET',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.green,
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: AppColors.green),
          ],
        ),
      ),
    );
  }
}
