import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../core/network/api_client.dart';
import '../core/storage/offline_cache.dart';
import '../models/models.dart';

/// Données métier : terrains, stats, propriétaires, transactions, alertes.
///
/// · Écoute la connectivité et expose `isOnline` (bandeau hors-ligne).
/// · En cas d'échec réseau, retombe sur le cache [OfflineCache] quand il
///   existe (champ `fromCache` à true pour l'affichage du bandeau).
class DataProvider extends ChangeNotifier {
  DataProvider() {
    Connectivity().onConnectivityChanged.listen((results) {
      isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();
    });
  }

  bool isOnline = true;

  // — Terrains —
  List<Terrain> terrains = [];
  bool terrainsLoading = false;
  bool terrainsFromCache = false;
  String? terrainsError;

  // — Stats —
  Stats? stats;
  bool statsFromCache = false;

  // — Propriétaires (formulaires) —
  List<Proprietaire> proprietaires = [];

  // — Transactions récentes (dashboard) —
  List<TransactionItem> transactionsRecentes = [];

  // — Alertes récentes (dashboard) —
  List<Alerte> alertesRecentes = [];

  // ─────────────────────────────────────────────────────────────── terrains
  Future<void> loadTerrains() async {
    terrainsLoading = true;
    terrainsError = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.dio.get('/api/terrains/');
      final list = _extractList(res.data);
      terrains = list.map(Terrain.fromJson).toList();
      terrainsFromCache = false;
      await OfflineCache.instance.put('terrains', terrains.map((t) => t.toJson()).toList());
    } on Object catch (e) {
      final cached = await OfflineCache.instance.get('terrains');
      if (cached is List && (cached.isNotEmpty || terrains.isEmpty)) {
        terrains = cached
            .whereType<Map>()
            .map((m) => Terrain.fromJson(Map<String, dynamic>.from(m)))
            .toList();
        terrainsFromCache = true;
      } else {
        terrainsError = ApiClient.messageOf(e);
      }
    }
    terrainsLoading = false;
    notifyListeners();
  }

  Future<Terrain?> fetchTerrain(int id) async {
    try {
      final res = await ApiClient.instance.dio.get('/api/terrains/$id/');
      if (res.statusCode == 200 && res.data is Map) {
        return Terrain.fromJson(res.data as Map<String, dynamic>);
      }
    } on Object {
      return _terrainFromLocal(id);
    }
    return _terrainFromLocal(id);
  }

  Terrain? _terrainFromLocal(int id) {
    for (final t in terrains) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Création d'un terrain (multipart si photo fournie).
  Future<String?> createTerrain({
    required String adresse,
    required String superficie,
    required int proprietaireId,
    String? coordonneesGps,
    String? photoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'adresse': adresse,
        'superficie': superficie,
        'proprietaire_actuel': proprietaireId,
        if (coordonneesGps != null && coordonneesGps.isNotEmpty)
          'coordonnees_gps': coordonneesGps,
      });
      if (photoPath != null) {
        form.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(photoPath, filename: 'terrain.jpg'),
        ));
      }
      final res = await ApiClient.instance.dio.post('/api/terrains/', data: form);
      if (res.statusCode == 201 || res.statusCode == 200) {
        await loadTerrains();
        return null;
      }
      return ApiClient.messageOf(Exception(res.statusCode));
    } on Object catch (e) {
      return ApiClient.messageOf(e);
    }
  }

  // ──────────────────────────────────────────────────────────────── stats
  Future<void> loadStats() async {
    try {
      final res = await ApiClient.instance.dio.get('/api/stats/');
      if (res.statusCode == 200 && res.data is Map) {
        stats = Stats.fromJson(res.data as Map<String, dynamic>);
        statsFromCache = false;
        await OfflineCache.instance.put('stats', stats!.parStatut.isEmpty
            ? <String, dynamic>{}
            : {
                'terrains_total': stats!.terrainsTotal,
                'transactions_total': stats!.transactionsTotal,
                'litiges_ouverts': stats!.litigesOuverts,
                'alertes_actives': stats!.alertesActives,
                'terrains_par_statut': stats!.parStatut,
              });
      }
    } on Object {
      final cached = await OfflineCache.instance.get('stats');
      if (cached is Map) {
        stats = Stats.fromJson(Map<String, dynamic>.from(cached));
        statsFromCache = true;
      }
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────── propriétaires
  Future<void> loadProprietaires() async {
    try {
      final res = await ApiClient.instance.dio.get('/api/proprietaires/');
      final list = _extractList(res.data);
      proprietaires = list.map(Proprietaire.fromJson).toList();
    } on Object {
      // silencieux : les formulaires afficheront une liste vide dégradable.
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────── transactions
  Future<void> loadTransactionsRecentes() async {
    try {
      final res = await ApiClient.instance.dio
          .get('/api/transactions/', queryParameters: {'ordering': '-date_transaction', 'page_size': 5});
      final list = _extractList(res.data);
      transactionsRecentes = list.map(TransactionItem.fromJson).toList();
    } on Object {
      // silencieux (dashboard dégradable).
    }
    notifyListeners();
  }

  /// Enregistre une transaction : POST /api/transactions/.
  Future<String?> createTransaction({
    required int terrainId,
    required int vendeurId,
    required int acheteurId,
    required String montant,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post('/api/transactions/', data: {
        'terrain': terrainId,
        'vendeur': vendeurId,
        'acheteur': acheteurId,
        'montant': montant,
      });
      if (res.statusCode == 201 || res.statusCode == 200) {
        await loadTransactionsRecentes();
        return null;
      }
      return ApiClient.messageOf(Exception(res.statusCode));
    } on Object catch (e) {
      return ApiClient.messageOf(e);
    }
  }

  // ─────────────────────────────────────────────────────────────── alertes
  Future<void> loadAlertesRecentes() async {
    try {
      final res = await ApiClient.instance.dio
          .get('/api/alertes/', queryParameters: {'ordering': '-date', 'page_size': 5});
      final list = _extractList(res.data);
      alertesRecentes = list.map(Alerte.fromJson).toList();
    } on Object {
      // silencieux.
    }
    notifyListeners();
  }

  /// Déclare un litige : POST /api/litiges/.
  Future<String?> createLitige({
    required int terrainId,
    required int declarantId,
    required String description,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post('/api/litiges/', data: {
        'terrain': terrainId,
        'declarant': declarantId,
        'description': description,
      });
      if (res.statusCode == 201 || res.statusCode == 200) return null;
      return ApiClient.messageOf(Exception(res.statusCode));
    } on Object catch (e) {
      return ApiClient.messageOf(e);
    }
  }

  /// Vérifie un document : POST /api/documents/verifier/.
  Future<DocumentVerdict?> verifierDocument(String code) async {
    try {
      final res = await ApiClient.instance.dio
          .post('/api/documents/verifier/', data: {'code': code});
      if (res.statusCode == 200 && res.data is Map) {
        return DocumentVerdict.fromJson(res.data as Map<String, dynamic>);
      }
      return DocumentVerdict(
        valide: false,
        message: 'Document introuvable ou code invalide.',
      );
    } on Object catch (e) {
      return DocumentVerdict(valide: false, message: ApiClient.messageOf(e));
    }
  }

  /// Télécharge le certificat PDF d'un terrain, le sauvegarde dans un
  /// fichier temporaire et renvoie son chemin (pour share_plus).
  Future<Object> telechargerCertificat(Terrain terrain) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/api/terrains/${terrain.id}/certificat/',
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.statusCode == 200 && res.data is List<int>) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/certificat-${terrain.idUnique ?? terrain.id}.pdf');
        await file.writeAsBytes(res.data as List<int>);
        return file;
      }
      return 'Certificat indisponible (HTTP ${res.statusCode}).';
    } on Object catch (e) {
      return ApiClient.messageOf(e);
    }
  }

  // — utilitaires —
  static List<dynamic> _extractList(Object? data) {
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return const [];
  }
}
