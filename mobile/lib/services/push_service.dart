import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_theme.dart';
import '../screens/terrains/terrain_detail_screen.dart';

/// Handler d'arrière-plan — DOIT être une fonction top-level.
/// Les notifications en arrière-plan/terminé sont affichées par le
/// système ; ici on initialise seulement Firebase avant le traitement.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Notifications push FCM.
///
/// · Enregistre le token de l'appareil auprès du backend
///   (POST /api/push-token/ — accepté au format FCM natif).
/// · Réagit aux messages premier-plan (bandeau in-app), aux taps
///   (navigation vers la fiche terrain si data.terrainId) et au
///   cold start depuis une notification.
///
/// Dégradation gracieuse : si Firebase n'est pas configuré (fichiers
/// google-services.json / GoogleService-Info.plist absents — voir
/// mobile/README.md), l'app fonctionne normalement sans push.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Clé du navigateur racine — à passer à MaterialApp.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  bool _firebaseReady = false;

  /// À appeler après chaque connexion réussie (token rattaché au compte).
  Future<void> initialize() async {
    // 1. Initialisation Firebase (une seule fois).
    if (!_firebaseReady) {
      try {
        await Firebase.initializeApp();
        _firebaseReady = true;
      } on Object catch (e) {
        debugPrint('[PushService] Firebase non configuré — push désactivé ($e)');
        return;
      }

      // 2. Permissions (iOS + Android 13+).
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Handlers de messages.
      FirebaseMessaging.onMessage.listen(_afficherBandeau);
      FirebaseMessaging.onMessageOpenedApp.listen(_ouvrirDepuisMessage);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _ouvrirDepuisMessage(initial);

      // 4. Rotation des tokens FCM.
      FirebaseMessaging.instance.onTokenRefresh
          .listen((_) => _enregistrerToken());
    }

    // 5. (Re-)enregistrement du token auprès du backend à chaque connexion.
    await _enregistrerToken();
  }

  Future<void> _enregistrerToken() async {
    if (!_firebaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await ApiClient.instance.dio.post(
        '/api/push-token/',
        data: {'token': token},
      );
    } on Object {
      // Non bloquant : l'app reste fonctionnelle sans push.
    }
  }

  /// Premier-plan : bandeau in-app (la bannière système est masquée).
  void _afficherBandeau(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final titre = message.notification?.title ?? 'TrustLand';
    final corps = message.notification?.body ?? '';
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 5),
      content: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              size: 18, color: Forest.green50),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              corps.isEmpty ? titre : '$titre — $corps',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'Voir',
        onPressed: () => _ouvrirDepuisMessage(message),
      ),
    ));
  }

  /// Tap sur notification → fiche terrain si data.terrainId présent.
  void _ouvrirDepuisMessage(RemoteMessage message) {
    final terrainId = int.tryParse('${message.data['terrainId'] ?? ''}');
    if (terrainId == null) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => TerrainDetailScreen(terrainId: terrainId),
    ));
  }
}
