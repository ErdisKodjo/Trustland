import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache hors-ligne léger (JSON dans SharedPreferences).
///
/// Stratégie volontairement simple : au dernier chargement réussi,
/// on garde une copie des listes critiques (terrains, stats). En mode
/// hors-ligne, l'écran affiche la copie + un bandeau « données en cache ».
class OfflineCache {
  OfflineCache._();
  static final OfflineCache instance = OfflineCache._();

  static const _prefix = 'tl_cache_';

  Future<void> put(String key, Object payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefix + key, jsonEncode(payload));
  }

  Future<Object?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefix + key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> purge() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
