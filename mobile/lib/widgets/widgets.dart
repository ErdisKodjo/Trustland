import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  BIBLIOTHÈQUE DE WIDGETS « CADASTRE »
///  Composants réutilisables — aucune duplication de styles dans les écrans.
/// ─────────────────────────────────────────────────────────────────────────────

/// Logo textuel TrustLand (T verte + mot-symbole).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44, this.compact = false});

  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Forest.green700,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          alignment: Alignment.center,
          child: Text(
            'T',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.55,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              children: const [
                TextSpan(
                  text: 'Trust',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(
                  text: 'Land',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
              style: TextStyle(
                fontSize: size * 0.42,
                color: Forest.ink,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Titre de section (sur-titre vert + trait).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Forest.green700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Forest.green900,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Carte statistique (accueil / dashboard) — bord gauche coloré.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.color = Forest.green700,
    this.icon = Icons.map_outlined,
  });

  final String label;
  final Object? value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Carte à accent gauche : bande colorée dans un ClipRRect
    // (évite l'assertion Flutter « non-uniform Border + borderRadius »).
    return ClipRRect(
      borderRadius: BorderRadius.circular(CadastreRadius.lg),
      child: Container(
        color: Forest.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3.5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: color),
                    const SizedBox(height: 8),
                    Text(
                      value?.toString() ?? '—',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      label,
                      style:
                          const TextStyle(fontSize: 11.5, color: Forest.mute),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge de statut de terrain (pill pastel + point).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.statut, {super.key, this.large = false});

  final String statut;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fg = Forest.statutColor(statut);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 9,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: Forest.statutBg(statut),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            Forest.statutLabel(statut),
            style: TextStyle(
              color: fg,
              fontSize: large ? 13 : 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte résumé d'un terrain (liste Terrains).
class TerrainCard extends StatelessWidget {
  const TerrainCard({super.key, required this.terrain, this.onTap});

  final Terrain terrain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final prop = terrain.proprietaireNom;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CadastreRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      terrain.adresse,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(terrain.statut),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _Meta(Icons.crop_free_outlined, terrain.superficieLabel),
                  if (prop != null) _Meta(Icons.person_outline, prop),
                  if (terrain.idUnique != null)
                    _Meta(Icons.tag_outlined, terrain.idUnique!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Forest.mute),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 12.5, color: Forest.mute),
        ),
      ],
    );
  }
}

/// État vide illustré (listes sans données).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Forest.green50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Forest.green700),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Forest.mute),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne « libellé → valeur » (détail terrain, profil).
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Forest.mute),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13.5, fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau hors-ligne (données en cache).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.fromCache = false});

  final bool fromCache;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Forest.amber600,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                fromCache
                    ? 'Hors ligne — données en cache (dernière synchro).'
                    : 'Hors ligne — reconnexion en cours…',
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Étiquette de champ de formulaire.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Forest.green900,
        ),
      ),
    );
  }
}

/// Bascule à intercepteur (équivalent model_popup_dialog Expo) —
/// feuille modale de sélection de propriétaire, filtrable.
class ProprietairePicker extends StatefulWidget {
  const ProprietairePicker({
    super.key,
    required this.items,
    required this.onSelect,
  });

  final List<Proprietaire> items;
  final void Function(Proprietaire) onSelect;

  @override
  State<ProprietairePicker> createState() => _ProprietairePickerState();
}

class _ProprietairePickerState extends State<ProprietairePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((p) =>
            '${p.prenom} ${p.nom} ${p.email ?? ''}'
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Forest.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Forest.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un propriétaire…',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'Aucun propriétaire trouvé',
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Forest.green50,
                            child: Text(
                              p.prenom.isNotEmpty ? p.prenom[0] : '?',
                              style: const TextStyle(
                                color: Forest.green700,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          title: Text(p.fullName),
                          subtitle: p.email != null ? Text(p.email!) : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onSelect(p);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre la feuille de sélection de propriétaire.
Future<void> showProprietairePicker(
  BuildContext context,
  List<Proprietaire> items,
  void Function(Proprietaire) onSelect,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProprietairePicker(items: items, onSelect: onSelect),
  );
}

/// Utilitaires de formatage FR.
abstract final class Fmt {
  static final NumberFormat _nf = NumberFormat.decimalPattern('fr_FR');

  /// « 12 345 ».
  static String number(num value) => _nf.format(value);

  /// « 12/09/2026 » depuis ISO.
  static String date(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd/MM/yyyy').format(d);
  }

  /// « 12/09/2026 à 14:30 » depuis ISO.
  static String dateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat("dd/MM/yyyy 'à' HH:mm").format(d);
  }

  /// Limite la saisie d'un champ texte numérique décimal.
  static List<TextInputFormatter> decimalInput() => [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
      ];
}

/// Affiche une erreur en SnackBar verte/rouge.
void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Forest.danger : null,
    ),
  );
}
