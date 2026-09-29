import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/lock/lock_screen.dart';
import 'screens/shell/app_shell.dart';
import 'screens/splash_screen.dart';
import 'services/push_service.dart';
import 'state/auth_provider.dart';
import 'state/data_provider.dart';

/// Racine applicative : providers, thème, navigation par état.
class TrustLandApp extends StatefulWidget {
  const TrustLandApp({super.key, required this.auth});

  final AuthProvider auth;

  @override
  State<TrustLandApp> createState() => _TrustLandAppState();
}

class _TrustLandAppState extends State<TrustLandApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.auth.onAppLifecycle(state);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.auth),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'TrustLand',
        debugShowCheckedModeBanner: false,
        navigatorKey: PushService.instance.navigatorKey,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

/// Routeur par état : splash → (login | shell) + overlay de verrouillage.
/// Déclenche l'initialisation du push dès qu'un utilisateur est connecté.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final connected = context.watch<AuthProvider>().user != null;
    if (connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PushService.instance.initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) return const SplashScreen();

    if (auth.user == null) return const LoginScreen();

    // Overlay de verrouillage au-dessus de l'app (inactivité 10 min).
    return Stack(
      children: [
        const AppShell(),
        if (auth.locked) const LockScreen(),
      ],
    );
  }
}
