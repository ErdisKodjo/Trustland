import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';
import 'terrain_detail_screen.dart';

/// Liste des terrains : recherche plein texte + filtres par statut.
class TerrainsScreen extends StatefulWidget {
  const TerrainsScreen({super.key});

  @override
  State<TerrainsScreen> createState() => _TerrainsScreenState();
}

class _TerrainsScreenState extends State<TerrainsScreen> {
  String _query = '';
  String? _statutFilter; // null = tous

  static const _filters = <(String?, String)>[
    (null, 'Tous'),
    ('libre', 'Libres'),
    ('en_transaction', 'En transaction'),
    ('litige', 'Litiges'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DataProvider>().loadTerrains(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    final filtered = data.terrains.where((t) {
      final matchStatut = _statutFilter == null || t.statut == _statutFilter;
      final q = _query.toLowerCase();
      final matchQuery = q.isEmpty ||
          t.adresse.toLowerCase().contains(q) ||
          (t.idUnique ?? '').toLowerCase().contains(q) ||
          (t.proprietaireNom ?? '').toLowerCase().contains(q);
      return matchStatut && matchQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terrains'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh, size: 22),
            onPressed: () => context.read<DataProvider>().loadTerrains(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_terrains',
        backgroundColor: Forest.green700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Nouveau',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TerrainFormScreen()),
          );
          if (context.mounted) {
            context.read<DataProvider>().loadTerrains();
          }
        },
      ),
      body: Column(
        children: [
          // — Recherche —
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher adresse, ID unique, propriétaire…',
                prefixIcon: Icon(Icons.search, size: 20),
                suffixIcon: Icon(Icons.tune, size: 18),
              ),
            ),
          ),

          // — Filtres statut —
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (value, label) = _filters[i];
                final selected = _statutFilter == value;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _statutFilter = value),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // — Liste —
          Expanded(
            child: _buildList(data, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildList(DataProvider data, List<Terrain> filtered) {
    if (data.terrainsLoading && data.terrains.isEmpty) {
      // Squelettes de chargement (esprit web).
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _SkeletonCard(),
        ),
      );
    }

    if (filtered.isEmpty && data.terrainsError != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Chargement impossible',
        subtitle: data.terrainsError,
      );
    }

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.map_outlined,
        title: 'Aucun terrain trouvé',
        subtitle: 'Ajustez la recherche ou les filtres de statut.',
      );
    }

    return RefreshIndicator(
      color: Forest.green700,
      onRefresh: () => context.read<DataProvider>().loadTerrains(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => TerrainCard(
          terrain: filtered[i],
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TerrainDetailScreen(terrainId: filtered[i].id),
          )),
        ),
      ),
    );
  }
}

/// Squelette de carte pendant le chargement.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Forest.surface,
        borderRadius: BorderRadius.circular(CadastreRadius.lg),
        border: Border.all(color: Forest.border),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonLine(width: 180, height: 14),
            SizedBox(height: 14),
            _SkeletonLine(width: 120, height: 11),
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Forest.green50,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
