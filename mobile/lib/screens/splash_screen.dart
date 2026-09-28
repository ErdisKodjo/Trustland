import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Écran de démarrage — palette Forest, plus aucun bleu générique.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Forest.green900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Forest.green700,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              alignment: Alignment.center,
              child: const Text(
                'T',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'Trust',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: 'Land',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Registre foncier numérique',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
