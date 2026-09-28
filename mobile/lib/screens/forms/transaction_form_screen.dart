import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';

/// Enregistrement d'une transaction foncière (vendeur → acheteur).
/// Optionnellement pré-remplie avec un terrain (depuis la fiche terrain).
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.initialTerrainId});

  final int? initialTerrainId;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _montantCtrl = TextEditingController();

  Terrain? _terrain;
  Proprietaire? _vendeur;
  Proprietaire? _acheteur;
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
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_terrain == null || _vendeur == null || _acheteur == null) {
      showAppSnack(
        context,
        'Renseignez le terrain, le vendeur et l\'acheteur.',
        error: true,
      );
      return;
    }
    if (_vendeur!.id == _acheteur!.id) {
      showAppSnack(context, 'Le vendeur et l\'acheteur doivent différer.',
          error: true);
      return;
    }
    final montant =
        double.tryParse(_montantCtrl.text.trim().replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      showAppSnack(context, 'Montant invalide.', error: true);
      return;
    }

    setState(() => _submitting = true);
    final error = await context.read<DataProvider>().createTransaction(
          terrainId: _terrain!.id,
          vendeurId: _vendeur!.id,
          acheteurId: _acheteur!.id,
          montant: montant.toStringAsFixed(0),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      showAppSnack(context, 'Transaction enregistrée et archivée.');
      Navigator.of(context).pop();
    } else {
      showAppSnack(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('Terrain concerné *'),
            InkWell(
              borderRadius: BorderRadius.circular(CadastreRadius.md),
              onTap: () => _pickTerrain(context.read<DataProvider>()),
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

            const FieldLabel('Vendeur (propriétaire actuel) *'),
            InkWell(
              borderRadius: BorderRadius.circular(CadastreRadius.md),
              onTap: () => showProprietairePicker(
                  context, data.proprietaires, (p) => setState(() => _vendeur = p)),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.expand_more, size: 20),
                ),
                child: Text(
                  _vendeur?.fullName ?? '— Choisir le vendeur —',
                  style: TextStyle(
                    fontSize: 14,
                    color: _vendeur == null ? Forest.mute : Forest.ink,
                  ),
                ),
              ),
            ),

            const FieldLabel('Acheteur (nouveau propriétaire) *'),
            InkWell(
              borderRadius: BorderRadius.circular(CadastreRadius.md),
              onTap: () => showProprietairePicker(
                  context, data.proprietaires, (p) => setState(() => _acheteur = p)),
              child: InputDecorator(
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.expand_more, size: 20),
                ),
                child: Text(
                  _acheteur?.fullName ?? '— Choisir l\'acheteur —',
                  style: TextStyle(
                    fontSize: 14,
                    color: _acheteur == null ? Forest.mute : Forest.ink,
                  ),
                ),
              ),
            ),

            const FieldLabel('Montant de la transaction (FCFA) *'),
            TextFormField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: Fmt.decimalInput(),
              decoration: const InputDecoration(hintText: 'ex. 12500000'),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Forest.infoBg,
                borderRadius: BorderRadius.circular(CadastreRadius.md),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Forest.info),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La transaction est archivée avec horodatage et peut être '
                      'ancrée sur la blockchain pour preuve définitive.',
                      style: TextStyle(fontSize: 12, color: Forest.info),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Enregistrer la transaction'),
            ),
          ],
        ),
      ),
    );
  }

  /// Sélecteur de terrain : liste simple filtrable en feuille modale.
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
