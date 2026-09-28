import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  DESIGN SYSTEM « CADASTRE » — palette Forest
///  Source de vérité : `frontend/src/index.css` (web).
///  Ne pas introduire d'autres couleurs : une seule identité web + mobile.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class Forest {
  // Brand
  static const Color green700 = Color(0xFF1E5A31); // vert cadastre (primaire)
  static const Color green900 = Color(0xFF12301C); // vert profond
  static const Color green50  = Color(0xFFEEF5EF); // surfaces teintées

  // Surfaces & texte
  static const Color canvas   = Color(0xFFFAF9F5); // toile os (fond app)
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color border   = Color(0xFFE4E6DC);
  static const Color ink      = Color(0xFF101510); // texte principal
  static const Color mute     = Color(0xFF5D675E); // texte secondaire

  // Sémantiques
  static const Color amber600 = Color(0xFFB45309); // alertes, mises en garde
  static const Color danger   = Color(0xFFB3261E);
  static const Color dangerBg = Color(0xFFFCEAE8);
  static const Color info     = Color(0xFF1D5C96); // bleu harmonisé du logo
  static const Color infoBg   = Color(0xFFE6EFF8);

  /// Couleur par statut de terrain.
  static Color statutColor(String statut) => switch (statut) {
        'libre' => green700,
        'en_transaction' => info,
        'litige' => danger,
        _ => mute,
      };

  /// Fond (pastel) par statut de terrain.
  static Color statutBg(String statut) => switch (statut) {
        'libre' => green50,
        'en_transaction' => infoBg,
        'litige' => dangerBg,
        _ => const Color(0xFFF1F5F9),
      };

  /// Libellé FR par statut.
  static String statutLabel(String statut) => switch (statut) {
        'libre' => 'Libre',
        'en_transaction' => 'En transaction',
        'litige' => 'En litige',
        _ => statut,
      };
}

/// Rayons d'angle (cohérents avec les cartes web, radius 14).
abstract final class CadastreRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 20;
}

/// ─────────────────────────────────────────────────────────────────────────────
///  THÈME MATERIAL 3 — construction manuelle (pas de ColorScheme.fromSeed :
///  la palette Forest doit rester exacte, pas « dérivée »).
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class AppTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: Forest.green700,
      onPrimary: Colors.white,
      primaryContainer: Forest.green50,
      onPrimaryContainer: Forest.green900,
      secondary: Forest.info,
      onSecondary: Colors.white,
      secondaryContainer: Forest.infoBg,
      onSecondaryContainer: Forest.info,
      error: Forest.danger,
      onError: Colors.white,
      errorContainer: Forest.dangerBg,
      onErrorContainer: Forest.danger,
      surface: Forest.surface,
      onSurface: Forest.ink,
      surfaceContainerHighest: Forest.canvas,
      onSurfaceVariant: Forest.mute,
      outline: Forest.border,
      outlineVariant: Forest.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Forest.canvas,
      splashFactory: InkSparkle.splashFactory,
    );

    return base.copyWith(
      // — Typographie : titres resserrés, esprit « registre officiel » —
      textTheme: base.textTheme.apply(
        bodyColor: Forest.ink,
        displayColor: Forest.ink,
      ).copyWith(
        headlineSmall: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5,
        ),
        titleLarge: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
        ),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
        bodySmall: const TextStyle(
          fontSize: 12.5, height: 1.4, color: Forest.mute,
        ),
        labelLarge: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2,
        ),
      ),

      // — AppBar : calme, ancrée sur la toile os —
      appBarTheme: const AppBarTheme(
        backgroundColor: Forest.canvas,
        foregroundColor: Forest.ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800,
          color: Forest.ink, letterSpacing: -0.2,
        ),
      ),

      // — Cartes : bordure fine, ombre quasi nulle (esprit web) —
      cardTheme: CardThemeData(
        color: Forest.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.lg),
          side: const BorderSide(color: Forest.border),
        ),
      ),

      // — Boutons pleins : vert cadastre, coins md —
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Forest.green700,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CadastreRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Forest.green700,
          side: const BorderSide(color: Forest.green700, width: 1.2),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CadastreRadius.md),
          ),
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Forest.green700,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // — Champs : remplis, bordure fine, focus vert —
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Forest.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.md),
          borderSide: const BorderSide(color: Forest.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.md),
          borderSide: const BorderSide(color: Forest.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.md),
          borderSide: const BorderSide(color: Forest.green700, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.md),
          borderSide: const BorderSide(color: Forest.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.md),
          borderSide: const BorderSide(color: Forest.danger, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Forest.mute, fontSize: 14),
        labelStyle: const TextStyle(color: Forest.mute, fontSize: 14),
      ),

      // — Chips de filtre —
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Forest.surface,
        selectedColor: Forest.green50,
        side: const BorderSide(color: Forest.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.sm),
        ),
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),

      // — Barre de navigation basse —
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Forest.surface,
        indicatorColor: Forest.green50,
        elevation: 0,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Forest.green700 : Forest.mute,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? Forest.green700 : Forest.mute,
          );
        }),
      ),

      // — Separateurs, progress, snackbars —
      dividerTheme: const DividerThemeData(color: Forest.border, thickness: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Forest.green700,
        linearTrackColor: Forest.green50,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Forest.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CadastreRadius.md),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Forest.mute,
        titleTextStyle: TextStyle(
          fontSize: 14.5, fontWeight: FontWeight.w600, color: Forest.ink,
        ),
        subtitleTextStyle: TextStyle(fontSize: 12.5, color: Forest.mute),
      ),
    );
  }
}
