import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';
import '../terrains/terrain_detail_screen.dart';

/// Carte cadastrale — tuiles OpenStreetMap (aucune clé API requise).
/// Marqueurs colorés par statut ; popup de focus sur un terrain.
class CarteScreen extends StatefulWidget {
  const CarteScreen({super.key});

  @override
  State<CarteScreen> createState() => _CarteScreenState();
}

class _CarteScreenState extends State<CarteScreen> {
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DataProvider>().loadTerrains(),
    );
  }

  LatLng? _parseGps(String? gps) {
    if (gps == null || !gps.contains(',')) return null;
    final parts = gps.split(',').map((s) => double.tryParse(s.trim())).toList();
    if (parts.length != 2 || parts[0] == null || parts[1] == null) return null;
    return LatLng(parts[0]!, parts[1]!);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final points = <(Terrain, LatLng)>[];
    for (final t in data.terrains) {
      final p = _parseGps(t.coordonneesGps);
      if (p != null) points.add((t, p));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Carte cadastrale')),
      body: Column(
        children: [
          // Légende (esprit web — pills pastel).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Forest.surface,
            child: Row(
              children: [
                _LegendDot(Forest.green700, 'Libre'),
                const SizedBox(width: 14),
                _LegendDot(Forest.info, 'En transaction'),
                const SizedBox(width: 14),
                _LegendDot(Forest.danger, 'Litige'),
                const Spacer(),
                Text(
                  '${points.length} localisé(s)',
                  style: const TextStyle(fontSize: 11.5, color: Forest.mute),
                ),
              ],
            ),
          ),
          Expanded(
            child: points.isEmpty && !data.terrainsLoading
                ? const EmptyState(
                    icon: Icons.public_off_outlined,
                    title: 'Aucun terrain géolocalisé',
                    subtitle:
                        'Les terrains doivent avoir des coordonnées GPS pour apparaître sur la carte.',
                  )
                : FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: points.isNotEmpty ? points.first.$2
                          : const LatLng(6.1319, 1.2228), // Lomé
                      initialZoom: 13,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.trustland.app',
                      ),
                      MarkerLayer(
                        markers: points.map((entry) {
                          final (t, p) = entry;
                          return Marker(
                            point: p,
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () => _focusTerrain(t),
                              child: _TerrainMarker(statut: t.statut),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _focusTerrain(Terrain t) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Forest.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.adresse,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
                StatusBadge(t.statut),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${t.superficieLabel} · ${t.proprietaireNom ?? 'propriétaire non renseigné'}',
              style: const TextStyle(fontSize: 13, color: Forest.mute),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TerrainDetailScreen(terrainId: t.id),
                  ));
                },
                child: const Text('Ouvrir la fiche terrain'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11.5)),
      ],
    );
  }
}

class _TerrainMarker extends StatelessWidget {
  const _TerrainMarker({required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Forest.statutColor(statut),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.location_on, size: 18, color: Colors.white),
    );
  }
}
