import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/widgets.dart';

/// Profil : identité, rôle, infos de session, déconnexion.
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // — Carte identité —
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Forest.green700,
                    child: Text(
                      (user?.username.isNotEmpty ?? false)
                          ? user!.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.username ?? '—',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (user?.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user!.email!,
                      style: const TextStyle(
                          fontSize: 13, color: Forest.mute),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Forest.green50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      user?.roleLabel ?? 'Utilisateur',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Forest.green700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // — Informations de session —
          const SectionTitle('Session & sécurité'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Tokens JWT chiffrés'),
                  subtitle: const Text(
                      'Stockage Keychain / Keystore — jamais en clair.'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Verrouillage biométrique'),
                  subtitle: Text(
                    auth.biometricsAvailable
                        ? 'Disponible — verrouillage auto après 10 min d\'inactivité.'
                        : 'Non disponible sur cet appareil.',
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: const Text('Mode hors-ligne'),
                  subtitle: const Text(
                      'Les terrains consultés restent accessibles en cache.'),
                ),
              ],
            ),
          ),

          // — Déconnexion —
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Forest.dangerBg,
              foregroundColor: Forest.danger,
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Se déconnecter ?'),
                  content: const Text(
                      'Les tokens de session seront effacés de cet appareil.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Déconnexion',
                        style: TextStyle(color: Forest.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Se déconnecter'),
          ),

          const SizedBox(height: 16),
          const Text(
            'TrustLand Mobile v1.0.0 — QuadraTech\n'
            'TCCHackDefend 2026 · Registre foncier numérique',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Forest.mute, height: 1.5),
          ),
        ],
      ),
    );
  }
}
