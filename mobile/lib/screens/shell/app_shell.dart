import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_provider.dart';
import '../../state/data_provider.dart';
import '../../widgets/widgets.dart';
import '../carte/carte_screen.dart';
import '../home/home_screen.dart';
import '../profil/profil_screen.dart';
import '../terrains/terrains_screen.dart';
import '../verifier/verifier_screen.dart';

/// Coque de navigation : 5 onglets — Accueil, Terrains, Carte, Vérifier, Profil.
/// Un IndexedStack préserve l'état de chaque onglet (défilement, recherche).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    TerrainsScreen(),
    CarteScreen(),
    VerifierScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Bandeau hors-ligne au-dessus du contenu.
          if (!data.isOnline)
            OfflineBanner(fromCache: data.terrainsFromCache),
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Terrains',
          ),
          const NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Carte',
          ),
          const NavigationDestination(
            icon: Icon(Icons.verified_outlined),
            selectedIcon: Icon(Icons.verified),
            label: 'Vérifier',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_circle_outlined),
            selectedIcon: const Icon(Icons.account_circle),
            label: auth.user?.username ?? 'Profil',
          ),
        ],
      ),
    );
  }
}
