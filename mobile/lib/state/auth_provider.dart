import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../core/config.dart';
import '../core/network/api_client.dart';
import '../core/storage/offline_cache.dart';
import '../core/storage/token_store.dart';
import '../models/models.dart';

/// État d'authentification global.
///
/// · `login` / `logout` / restauration de session au démarrage.
/// · Verrouillage automatique après [kInactivityTimeout] en arrière-plan
///   (équivalent du LockScreen Expo) — déverrouillage par biométrie.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    ApiClient.instance.onSessionExpired = logout;
  }

  final TokenStore _tokens = TokenStore();
  final LocalAuthentication _localAuth = LocalAuthentication();

  User? user;
  bool loading = true; // restauration de session en cours
  bool locked = false;

  bool _canCheckBiometrics = false;
  bool get biometricsAvailable => _canCheckBiometrics;

  DateTime? _backgroundedAt;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  /// À brancher sur `WidgetsBindingObserver.didChangeAppLifecycleState`.
  void onAppLifecycle(AppLifecycleState state) {
    if (_lifecycle == AppLifecycleState.resumed &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      _backgroundedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed &&
        _backgroundedAt != null &&
        user != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      if (elapsed >= kInactivityTimeout) locked = true;
      _backgroundedAt = null;
    }
    _lifecycle = state;
  }

  /// Restaure la session au démarrage (jeton + /api/users/me/).
  Future<void> restoreSession() async {
    loading = true;
    notifyListeners();
    final access = await _tokens.readAccess();
    if (access != null) {
      try {
        final res = await ApiClient.instance.dio.get('/api/users/me/');
        if (res.statusCode == 200 && res.data is Map) {
          user = User.fromJson(res.data as Map<String, dynamic>);
        }
      } catch (_) {
        await _tokens.clearSession();
      }
    }
    await _checkBiometrics();
    loading = false;
    notifyListeners();
  }

  Future<void> _checkBiometrics() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      _canCheckBiometrics = supported && canCheck;
    } catch (_) {
      _canCheckBiometrics = false;
    }
  }

  /// Connexion : POST /api/token/ puis GET /api/users/me/.
  Future<String?> login(String username, String password) async {
    try {
      final res = await ApiClient.instance.dio
          .post('/api/token/', data: {'username': username, 'password': password});
      if (res.statusCode != 200 || res.data is! Map) {
        return 'Identifiants invalides.';
      }
      final data = res.data as Map;
      await _tokens.saveSession(
        access: data['access'] as String,
        refresh: data['refresh'] as String,
        username: username,
      );
      final me = await ApiClient.instance.dio.get('/api/users/me/');
      if (me.statusCode == 200 && me.data is Map) {
        user = User.fromJson(me.data as Map<String, dynamic>);
      }
      locked = false;
      notifyListeners();
      return null; // succès
    } on Object catch (e) {
      return ApiClient.messageOf(e);
    }
  }

  Future<void> logout() async {
    await _tokens.clearSession();
    await OfflineCache.instance.purge();
    user = null;
    locked = false;
    notifyListeners();
  }

  /// Tente un déverrouillage biométrique. Renvoie true si accepté.
  Future<bool> authenticateBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Déverrouillez TrustLand pour continuer',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  void unlock() {
    locked = false;
    notifyListeners();
  }
}
