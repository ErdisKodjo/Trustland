import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';

/// Création d'un terrain : adresse, superficie, propriétaire (sélecteur),
/// GPS automatique et photo optionnelle.
class TerrainFormScreen extends StatefulWidget {
  const TerrainFormScreen({super.key});

  @override
  State<TerrainFormScreen> createState() => _TerrainFormScreenState();
}

class _TerrainFormScreenState extends State<TerrainFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adresseCtrl = TextEditingController();
  final _superficieCtrl = TextEditingController();
  final _gpsCtrl = TextEditingController();

  Proprietaire? _proprietaire;
  String? _photoPath;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DataProvider>().loadProprietaires(),
    );
  }

  @override
  void dispose() {
    _adresseCtrl.dispose();
    _superficieCtrl.dispose();
    _gpsCtrl.dispose();
    super.dispose();
  }

  Future<void> _capturerGps() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Activez la localisation pour capturer les coordonnées.'),
        ));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          messenger.showSnackBar(const SnackBar(
            content: Text('Permission de localisation refusée.'),
          ));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Autorisez la localisation dans les paramètres.'),
        ));
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _gpsCtrl.text =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
    } on Object {
      messenger.showSnackBar(const SnackBar(
        content: Text('Impossible d\'obtenir la position GPS.'),
      ));
    }
  }

  Future<void> _choisirPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final result = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 82);
    if (result != null && mounted) {
      setState(() => _photoPath = result.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_proprietaire == null) {
      showAppSnack(context, 'Sélectionnez le propriétaire actuel.', error: true);
      return;
    }
    setState(() => _submitting = true);
    final error = await context.read<DataProvider>().createTerrain(
          adresse: _adresseCtrl.text.trim(),
          superficie: _superficieCtrl.text.trim().replaceAll(',', '.'),
          proprietaireId: _proprietaire!.id,
          coordonneesGps: _gpsCtrl.text.trim(),
          photoPath: _photoPath,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      showAppSnack(context, 'Terrain enregistré avec succès.');
      Navigator.of(context).pop();
    } else {
      showAppSnack(context, error, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proprietaires = context.watch<DataProvider>().proprietaires;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau terrain')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FieldLabel('Adresse du terrain *'),
              TextFormField(
                controller: _adresseCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Quartier, canton, repères…',
                ),
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Adresse trop courte (5 caractères min.).'
                    : null,
              ),

              const FieldLabel('Superficie (m²) *'),
              TextFormField(
                controller: _superficieCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: Fmt.decimalInput(),
                decoration: const InputDecoration(hintText: 'ex. 1250'),
                validator: (v) {
                  final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (v == null || v.isEmpty || val == null || val <= 0) {
                    return 'Superficie invalide.';
                  }
                  return null;
                },
              ),

              const FieldLabel('Propriétaire actuel *'),
              InkWell(
                borderRadius: BorderRadius.circular(CadastreRadius.md),
                onTap: () => showProprietairePicker(
                    context, proprietaires, (p) => setState(() => _proprietaire = p)),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.expand_more, size: 20),
                  ),
                  child: Text(
                    _proprietaire?.fullName ?? '— Choisir un propriétaire —',
                    style: TextStyle(
                      fontSize: 14,
                      color: _proprietaire == null ? Forest.mute : Forest.ink,
                    ),
                  ),
                ),
              ),

              const FieldLabel('Coordonnées GPS'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gpsCtrl,
                      decoration: const InputDecoration(
                        hintText: 'lat, lon',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    tooltip: 'Capturer la position actuelle',
                    onPressed: _capturerGps,
                    icon: const Icon(Icons.my_location, size: 20),
                  ),
                ],
              ),

              const FieldLabel('Photo du terrain (optionnel)'),
              InkWell(
                borderRadius: BorderRadius.circular(CadastreRadius.md),
                onTap: _choisirPhoto,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Forest.green50,
                    borderRadius: BorderRadius.circular(CadastreRadius.md),
                    border: Border.all(color: Forest.border),
                  ),
                  alignment: Alignment.center,
                  child: _photoPath != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Forest.green700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Photo jointe — appuyer pour changer',
                              style: TextStyle(
                                  fontSize: 12.5, color: Forest.green900),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: Forest.green700),
                            SizedBox(height: 6),
                            Text('Caméra ou galerie',
                                style: TextStyle(
                                    fontSize: 12.5, color: Forest.mute)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Enregistrer le terrain'),
              ),
              const SizedBox(height: 8),
              const Text(
                '* champs obligatoires — l\'enregistrement génère un ID unique '
                'et un QR code d\'authenticité.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Forest.mute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
