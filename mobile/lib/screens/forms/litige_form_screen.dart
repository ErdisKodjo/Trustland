import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';

/// Déclaration d'un litige foncier (terrain + déclarant + description).
class LitigeFormScreen extends StatefulWidget {
  const LitigeFormScreen({super.key, this.initialTerrainId});

  final int? initialTerrainId;

  @override
  State<LitigeFormScreen> createState() => _LitigeFormScreenState();
}

class _LitigeFormScreenState extends State<LitigeFormScreen> {
  final _descriptionCtrl = TextEditingController();

  Terrain? _terrain;
  Proprietaire? _declarant;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = context.read<DataProvider>();
      await data.loadProprietaires();
      if (widget.initialTerrainId != null) {
        final t = await data.fetchTerrain(widget.initialTerrainId!);
        if (t != null && mounted) setState(() => _terrain = t);
      }
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_terrain == null || _declarant == null) {
      showAppSnack(context, 'Renseignez le terrain et le déclarant.',
          error: true);
      return;
    }
    final description = _descriptionCtrl.text.trim();
    if (description.length < 10) {
      showAppSnack(
        context,
        'Décrivez le litige (10 caractères minimum).',
        error: true,
      );
      return;
    }

    setState(() => _submitting = true);
    final error = await context.read<DataProvider>().createLitige(
          terrainId: _terrain!.id,
          declarantId: _declarant!.id,
          description: description,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      showAppSnack(context, 'Litige déclaré — l\'équipe va l\'instruire.');
      Navigator.of(context).pop();
    } else {
      showAppSnack(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Déclarer un litige')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // — Bandeau d'avertissement (ambre, esprit web) —
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF3E8),
                borderRadius: BorderRadius.circular(CadastreRadius.md),
                border: Border.all(color: Forest.amber600),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 18, color: Forest.amber600),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Une déclaration de litige bloque automatiquement les '
                      'transactions sur le terrain concerné.',
                      style: TextStyle(fontSize: 12.5, color: Forest.amber600),
                    ),
                  ),
                ],
              ),
            ),

            const FieldLabel('Terrain concerné *'),
            InkWell(
              borderRadius: BorderRadius.circular(CadastreRadius.md),
              onTap: () => _pickTerrain(data),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.expand_more, size: 20),
                ),
                child: Text(
                  _terrain?.adresse ?? '— Choisir un terrain —',
                  style: TextStyle(
                    fontSize: 14,
                    color: _terrain == null ? Forest.mute : Forest.ink,
                  ),
                ),
              ),
            ),

            const FieldLabel('Déclarant *'),
            InkWell(
              borderRadius: BorderRadius.circular(CadastreRadius.md),
              onTap: () => showProprietairePicker(
                  context, data.proprietaires, (p) => setState(() => _declarant = p)),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.expand_more, size: 20),
                ),
                child: Text(
                  _declarant?.fullName ?? '— Choisir le déclarant —',
                  style: TextStyle(
                    fontSize: 14,
                    color: _declarant == null ? Forest.mute : Forest.ink,
                  ),
                ),
              ),
            ),

            const FieldLabel('Description du litige *'),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                    'Décrivez la nature du litige : bornage, double vente, '
                    'succession, empiètement…',
              ),
            ),

            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Forest.danger),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Déclarer le litige'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTerrain(DataProvider data) async {
    await data.loadTerrains();
    if (!mounted) return;
    final selected = await showModalBottomSheet<Terrain>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Forest.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: data.terrains.length,
            itemBuilder: (context, i) {
              final t = data.terrains[i];
              return ListTile(
                title: Text(
                  t.adresse,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${t.superficieLabel} · ${t.idUnique ?? '—'}'),
                trailing: StatusBadge(t.statut),
                onTap: () => Navigator.pop(context, t),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _terrain = selected);
  }
}
