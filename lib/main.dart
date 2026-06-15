import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'game/game_controller.dart';
import 'screens/auth_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/username_screen.dart';
import 'services/api_config.dart';
import 'services/auth_service.dart';
import 'services/firebase_init.dart';
import 'services/settings_service.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(
          create: (ctx) => GameController(
            ctx.read<SettingsService>(),
            wsUrl: kWsServerUrl,
            auth: ctx.read<AuthService>(),
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
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final Widget home;
        switch (auth.authState) {
          case AuthState.loading:
            home = const _Splash();
          case AuthState.needsUsername:
            home = const UsernameScreen();
          case AuthState.authenticated:
            home = const MenuScreen();
          case AuthState.unauthenticated:
            home = const AuthScreen();
        }

        return MaterialApp(
          title: 'PUCKET',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: home,
        );
      },
    );
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
