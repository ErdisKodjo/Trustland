import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/auth_provider.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';
import '../forms/litige_form_screen.dart';
import '../forms/transaction_form_screen.dart';
import '../terrains/terrain_form_screen.dart';

/// Accueil : salutation, statistiques clés, raccourcis, dernières alertes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final data = context.read<DataProvider>();
    await Future.wait([
      data.loadStats(),
      data.loadAlertesRecentes(),
      data.loadTerrains(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final stats = data.stats;
    final role = auth.user?.roleLabel ?? '—';

    return RefreshIndicator(
      color: Forest.green700,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // — En-tête —
          Row(
            children: [
              const AppLogo(size: 40),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Forest.green50,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  role,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Forest.green700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Bonjour,',
            style: const TextStyle(fontSize: 15, color: Forest.mute),
          ),
          Text(
            auth.user?.username ?? '—',
            style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Voici l\'état du cadastre aujourd\'hui.',
            style: TextStyle(fontSize: 13, color: Forest.mute),
          ),

          // — Statistiques —
          const SectionTitle('Statistiques du registre'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatCard(
                label: 'Terrains total',
                value: stats?.terrainsTotal,
                icon: Icons.map_outlined,
              ),
              StatCard(
                label: 'Terrains libres',
                value: stats?.parStatut['libre'],
                icon: Icons.check_circle_outline,
              ),
              StatCard(
                label: 'En transaction',
                value: stats?.parStatut['en_transaction'],
                color: Forest.info,
                icon: Icons.swap_horiz_outlined,
              ),
              StatCard(
                label: 'En litige',
                value: stats?.parStatut['litige'],
                color: Forest.danger,
                icon: Icons.gavel_outlined,
              ),
              StatCard(
                label: 'Transactions',
                value: stats?.transactionsTotal,
                icon: Icons.receipt_long_outlined,
              ),
              StatCard(
                label: 'Alertes IA',
                value: stats?.alertesActives,
                color: (stats?.alertesActives ?? 0) > 0
                    ? Forest.amber600
                    : Forest.green700,
                icon: Icons.notifications_active_outlined,
              ),
            ],
          ),

          // — Raccourcis —
          const SectionTitle('Actions rapides'),
          Row(
            children: [
              Expanded(
                child: _QuickLink(
                  icon: Icons.add_location_alt_outlined,
                  label: 'Nouveau terrain',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TerrainFormScreen(),
                  )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickLink(
                  icon: Icons.swap_horiz_outlined,
                  label: 'Transaction',
                  color: Forest.info,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const TransactionFormScreen(),
                  )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickLink(
                  icon: Icons.gavel_outlined,
                  label: 'Litige',
                  color: Forest.danger,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LitigeFormScreen(),
                  )),
                ),
              ),
            ],
          ),

          // — Dernières alertes —
          if (data.alertesRecentes.isNotEmpty) ...[
            const SectionTitle('Dernières alertes IA'),
            ...data.alertesRecentes.take(3).map(_AlertTile.new),
          ],

          if (data.statsFromCache) ...[
            const SectionTitle('Données'),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_outlined,
                        size: 16, color: Forest.amber600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Données en cache — reconnectez-vous pour actualiser.',
                        style: TextStyle(fontSize: 12.5, color: Forest.mute),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Raccourci d'action (icône pastel + libellé).
class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Forest.green700,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Forest.surface,
      borderRadius: BorderRadius.circular(CadastreRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CadastreRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Forest.border),
            borderRadius: BorderRadius.circular(CadastreRadius.lg),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tuile d'alerte (niveau coloré).
class _AlertTile extends StatelessWidget {
  const _AlertTile(this.alerte);

  final Alerte alerte;

  Color get _levelColor => switch (alerte.niveau) {
        'critique' || 'eleve' || 'élevé' => Forest.danger,
        'moyen' => Forest.amber600,
        _ => Forest.info,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CadastreRadius.lg),
        child: Container(
          color: Forest.surface,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3.5, color: _levelColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alerte.titre ?? 'Alerte',
                              style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            Fmt.date(alerte.date),
                            style: const TextStyle(
                              fontSize: 11.5, color: Forest.mute,
                            ),
                          ),
                        ],
                      ),
                      if (alerte.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          alerte.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5, color: Forest.mute,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
