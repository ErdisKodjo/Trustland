import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';

/// Vérification de documents : saisie manuelle du code ou scan QR.
/// POST /api/documents/verifier/ → verdict authenticity.
class VerifierScreen extends StatefulWidget {
  const VerifierScreen({super.key});

  @override
  State<VerifierScreen> createState() => _VerifierScreenState();
}

class _VerifierScreenState extends State<VerifierScreen> {
  final _codeCtrl = TextEditingController();
  DocumentVerdict? _verdict;
  bool _checking = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifier(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      showAppSnack(context, 'Entrez un code de document.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _checking = true;
      _verdict = null;
    });
    final verdict = await context.read<DataProvider>().verifierDocument(trimmed);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _verdict = verdict;
    });
  }

  Future<void> _scanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScannerScreen()),
    );
    if (code != null && code.isNotEmpty && mounted) {
      _codeCtrl.text = code;
      await _verifier(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérifier un document')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // — Héro —
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Forest.green900,
                borderRadius: BorderRadius.circular(CadastreRadius.xl),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 40, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    'Contrôle d\'authenticité',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scannez le QR code d\'un certificat ou saisissez son code '
                    'pour vérifier son enregistrement au registre foncier.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            // — Scan QR —
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _scanner,
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              label: const Text('Scanner le QR code'),
            ),

            // — Saisie manuelle —
            const FieldLabel('… ou saisir le code du document'),
            TextFormField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'ex. TL-2026-004312',
              ),
              onFieldSubmitted: _verifier,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _checking ? null : () => _verifier(_codeCtrl.text),
              child: _checking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : const Text('Vérifier'),
            ),

            // — Verdict —
            if (_verdict != null) ...[
              const SizedBox(height: 24),
              _VerdictCard(verdict: _verdict!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carte de verdict (validé / refusé) — couleurs sémantiques du système.
class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});

  final DocumentVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final ok = verdict.valide;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ok ? Forest.green50 : Forest.dangerBg,
        borderRadius: BorderRadius.circular(CadastreRadius.lg),
        border: Border.all(color: ok ? Forest.green700 : Forest.danger),
      ),
      child: Column(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 44,
            color: ok ? Forest.green700 : Forest.danger,
          ),
          const SizedBox(height: 10),
          Text(
            ok ? 'Document authentique' : 'Document non reconnu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ok ? Forest.green900 : Forest.danger,
            ),
          ),
          if (verdict.message != null) ...[
            const SizedBox(height: 6),
            Text(
              verdict.message!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Forest.mute),
            ),
          ],
          if (verdict.details != null &&
              verdict.details!['terrain_detail'] is Map) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Forest.surface,
                borderRadius: BorderRadius.circular(CadastreRadius.md),
              ),
              child: Column(
                children: [
                  InfoRow(
                    label: 'Terrain',
                    value: (verdict.details!['terrain_detail']
                            as Map)['adresse'] as String? ??
                        '—',
                  ),
                  InfoRow(
                    label: 'Type',
                    value:
                        (verdict.details!['type_document'] ?? '—').toString(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scanner plein écran (mobile_scanner).
class _ScannerScreen extends StatefulWidget {
  const _ScannerScreen();

  @override
  State<_ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<_ScannerScreen> {
  bool _handled = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    if (capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner le QR code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Cadre de visée.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'Alignez le QR code du certificat dans le cadre',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
