/// Configuration réseau de TrustLand Mobile.
///
/// ⚠️  Ne jamais utiliser `localhost` sur un appareil physique :
/// remplacer par l'IP locale de la machine (`ifconfig` / `ipconfig`).
/// Pour l'émulateur Android, `10.0.2.2` pointe vers le host.
const String kApiBaseUrl = String.fromEnvironment(
  'TRUSTLAND_API',
  defaultValue: 'http://192.168.1.70:8000',
);

/// Timeouts réseau (ms).
const int kConnectTimeoutMs = 15000;
const int kReceiveTimeoutMs = 20000;

/// Verrouillage automatique après inactivité (arrière-plan).
const Duration kInactivityTimeout = Duration(minutes: 10);
