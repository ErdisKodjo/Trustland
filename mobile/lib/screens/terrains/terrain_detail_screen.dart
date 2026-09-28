import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';
import '../forms/litige_form_screen.dart';
import '../forms/transaction_form_screen.dart';

/// Détail d'un terrain : identité, superficie/GPS, propriétaire,
/// historique des transactions, QR code, certificat PDF, actions.
class TerrainDetailScreen extends StatefulWidget {
  const TerrainDetailScreen({super.key, required this.terrainId});

  final int terrainId;

  @override
  State<TerrainDetailScreen> createState() => _TerrainDetailScreenState();
}

class _TerrainDetailScreenState extends State<TerrainDetailScreen> {
  Terrain? terrain;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final t = await context.read<DataProvider>().fetchTerrain(widget.terrainId);
    if (!mounted) return;
    setState(() {
      terrain = t;
      loading = false;
      if (t == null) error = 'Terrain introuvable.';
    });
  }

  Future<void> _telechargerCertificat() async {
    if (terrain == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Téléchargement du certificat…')),
    );
    final result =
        await context.read<DataProvider>().telechargerCertificat(terrain!);
    if (!mounted) return;
    if (result is String && !result.endsWith('.pdf')) {
      messenger.showSnackBar(SnackBar(
        content: Text(result),
        backgroundColor: Forest.danger,
      ));
      return;
    }
    await Share.shareXFiles(
      [XFile((result as String))],
      subject: 'Certificat de propriété — ${terrain!.adresse}',
      text: 'Certificat de propriété TrustLand — ${terrain!.adresse}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = terrain;

    return Scaffold(
      appBar: AppBar(
        title: Text(t == null ? 'Détail terrain' : _short(t.adresse)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null || t == null
              ? EmptyState(
                  icon: Icons.error_outline,
                  title: 'Impossible de charger le terrain',
                  subtitle: error,
                )
              : RefreshIndicator(
                  color: Forest.green700,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // — En-tête —
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t!.adresse,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          StatusBadge(t.statut, large: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID unique : ${t.idUnique ?? '—'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Forest.mute,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),

                      // — Caractéristiques —
                      const SectionTitle('Caractéristiques'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          child: Column(
                            children: [
                              InfoRow(
                                label: 'Superficie',
                                value: t.superficieLabel,
                              ),
                              const Divider(height: 1),
                              InfoRow(
                                label: 'Coordonnées GPS',
                                value: t.coordonneesGps ?? '—',
                              ),
                              const Divider(height: 1),
                              InfoRow(
                                label: 'Enregistré le',
                                value: Fmt.date(t.dateEnregistrement),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // — Propriétaire —
                      const SectionTitle('Propriétaire actuel'),
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Forest.green50,
                            child: Text(
                              _initial(t),
                              style: const TextStyle(
                                color: Forest.green700,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(t.proprietaireNom ?? 'Non renseigné'),
                          subtitle: Text(
                            t.proprietaireActuel?['email'] as String? ??
                                'Contact non disponible',
                          ),
                          trailing: const Icon(Icons.verified_user_outlined,
                              size: 20, color: Forest.green700),
                        ),
                      ),

                      // — Certificat —
                      const SectionTitle('Certificat de propriété'),
                      OutlinedButton.icon(
                        onPressed: _telechargerCertificat,
                        icon: const Icon(Icons.download_outlined, size: 20),
                        label: const Text('Télécharger le certificat PDF'),
                      ),

                      // — QR code —
                      if (t.qrCode != null) ...[
                        const SectionTitle('QR code d\'authenticité'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(CadastreRadius.sm),
                                  child: Image.network(
                                    t.qrCode!.startsWith('http')
                                        ? t.qrCode!
                                        : '$kApiBaseUrl${t.qrCode!}',
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 84,
                                      height: 84,
                                      color: Forest.green50,
                                      child: const Icon(Icons.qr_code_2,
                                          size: 40, color: Forest.green700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    'Ce QR code relie le terrain physique à '
                                    'son enregistrement numérique. Scannez-le '
                                    'dans l\'onglet « Vérifier » pour contrôler '
                                    'un document.',
                                    style: TextStyle(
                                        fontSize: 12.5, color: Forest.mute),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // — Actions —
                      const SectionTitle('Actions'),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TransactionFormScreen(initialTerrainId: t.id),
                                ),
                              ),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Transférer'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LitigeFormScreen(initialTerrainId: t.id),
                                ),
                              ),
                              icon: const Icon(Icons.gavel_outlined, size: 18),
                              label: const Text('Déclarer litige'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  String _short(String s) =>
      s.length <= 30 ? s : '${s.substring(0, 30)}…';

  String _initial(Terrain t) {
    final nom = t.proprietaireNom;
    if (nom == null || nom.isEmpty) return '?';
    return nom[0].toUpperCase();
  }
}
