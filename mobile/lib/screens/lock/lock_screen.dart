import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/auth_provider.dart';
import '../../widgets/widgets.dart';

/// Overlay de verrouillage (inactivité 10 min en arrière-plan).
/// Déverrouillage biométrique si disponible, sinon mot de passe via logout.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _prompted = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tryBiometricOnce();
  }

  Future<void> _tryBiometricOnce() async {
    final auth = context.read<AuthProvider>();
    if (_prompted || !auth.biometricsAvailable) return;
    _prompted = true;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final auth = context.read<AuthProvider>();
    setState(() => _loading = true);
    final ok = await auth.authenticateBiometric();
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) auth.unlock();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Positioned.fill(
      child: Material(
        color: Colors.black87,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Forest.surface,
              borderRadius: BorderRadius.circular(CadastreRadius.xl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Forest.green700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'T',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Application verrouillée',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vous avez été inactif pendant 10 minutes.\n'
                  'Déverrouillez pour continuer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Forest.mute, height: 1.45),
                ),
                const SizedBox(height: 24),
                if (auth.biometricsAvailable)
                  FilledButton(
                    onPressed: _loading ? null : _tryBiometric,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Déverrouiller avec la biométrie'),
                  )
                else
                  Text(
                    'Biométrie non disponible sur cet appareil',
                    style: const TextStyle(fontSize: 12.5, color: Forest.mute),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().logout(),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
