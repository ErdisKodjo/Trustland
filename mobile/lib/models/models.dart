/// Modèles de données TrustLand — parsing défensif des réponses DRF.
///
/// Les champs nullable reflètent la réalité de l'API (certains détails
/// sont absents selon le rôle de l'utilisateur connecté).
library;

class User {
  const User({
    required this.id,
    required this.username,
    this.email,
    this.prenom,
    this.nom,
    this.role,
  });

  final int id;
  final String username;
  final String? email;
  final String? prenom;
  final String? nom;
  final String? role;

  /// Libellé FR du rôle (admin / agent / proprietaire).
  String get roleLabel => switch (role) {
        'admin' => 'Administrateur',
        'agent' => 'Agent',
        'proprietaire' => 'Propriétaire',
        _ => role ?? 'Utilisateur',
      };

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: (j['id'] as num?)?.toInt() ?? 0,
        username: (j['username'] ?? '') as String,
        email: j['email'] as String?,
        prenom: j['prenom'] as String?,
        nom: j['nom'] as String?,
        role: j['role'] as String?,
      );
}

class Proprietaire {
  const Proprietaire({
    required this.id,
    required this.prenom,
    required this.nom,
    this.email,
    this.telephone,
  });

  final int id;
  final String prenom;
  final String nom;
  final String? email;
  final String? telephone;

  String get fullName => '$prenom $nom';

  factory Proprietaire.fromJson(Map<String, dynamic> j) => Proprietaire(
        id: (j['id'] as num?)?.toInt() ?? 0,
        prenom: (j['prenom'] ?? '') as String,
        nom: (j['nom'] ?? '') as String,
        email: j['email'] as String?,
        telephone: j['telephone'] as String?,
      );
}

class Terrain {
  const Terrain({
    required this.id,
    required this.adresse,
    this.idUnique,
    this.statut = 'libre',
    this.superficie,
    this.coordonneesGps,
    this.dateEnregistrement,
    this.qrCode,
    this.photo,
    this.proprietaireActuel,
  });

  final int id;
  final String adresse;
  final String? idUnique;
  final String statut;
  final String? superficie;
  final String? coordonneesGps;
  final String? dateEnregistrement;
  final String? qrCode;
  final String? photo;

  /// Détail imbriqué DRF : {id, prenom, nom, email…}
  final Map<String, dynamic>? proprietaireActuel;

  String? get proprietaireNom {
    final p = proprietaireActuel;
    if (p == null) return null;
    final prenom = p['prenom'] ?? '';
    final nom = p['nom'] ?? '';
    return ('$prenom $nom').trim();
  }

  /// Superficie formatée « 12 345 m² ».
  String get superficieLabel {
    final raw = double.tryParse(superficie ?? '');
    if (raw == null) return '— m²';
    final s = raw
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$s m²';
  }

  factory Terrain.fromJson(Map<String, dynamic> j) => Terrain(
        id: (j['id'] as num?)?.toInt() ?? 0,
        adresse: (j['adresse'] ?? '') as String,
        idUnique: j['id_unique'] as String?,
        statut: (j['statut'] ?? 'libre') as String,
        superficie: j['superficie']?.toString(),
        coordonneesGps: j['coordonnees_gps'] as String?,
        dateEnregistrement: j['date_enregistrement'] as String?,
        qrCode: j['qr_code'] as String?,
        photo: j['photo'] as String?,
        proprietaireActuel: j['proprietaire_actuel_detail'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'adresse': adresse,
        'id_unique': idUnique,
        'statut': statut,
        'superficie': superficie,
        'coordonnees_gps': coordonneesGps,
        'date_enregistrement': dateEnregistrement,
        'qr_code': qrCode,
        'photo': photo,
        'proprietaire_actuel_detail': proprietaireActuel,
      };
}

class TransactionItem {
  const TransactionItem({
    required this.id,
    this.terrain,
    this.vendeur,
    this.acheteur,
    this.montant,
    this.dateTransaction,
  });

  final int id;
  final Map<String, dynamic>? terrain;
  final String? vendeur;
  final String? acheteur;
  final String? montant;
  final String? dateTransaction;

  /// Montant formaté « 12 500 000 FCFA ».
  String get montantLabel {
    final raw = double.tryParse(montant ?? '');
    if (raw == null) return '— FCFA';
    final s = raw
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
    return '$s FCFA';
  }

  factory TransactionItem.fromJson(Map<String, dynamic> j) => TransactionItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        terrain: j['terrain_detail'] as Map<String, dynamic>?,
        vendeur: j['vendeur'] as String?,
        acheteur: j['acheteur'] as String?,
        montant: j['montant']?.toString(),
        dateTransaction: j['date_transaction'] as String?,
      );
}

class Alerte {
  const Alerte({
    required this.id,
    this.titre,
    this.description,
    this.niveau,
    this.date,
    this.terrainId,
  });

  final int id;
  final String? titre;
  final String? description;
  final String? niveau;
  final String? date;
  final int? terrainId;

  factory Alerte.fromJson(Map<String, dynamic> j) => Alerte(
        id: (j['id'] as num?)?.toInt() ?? 0,
        titre: j['titre'] as String?,
        description: j['description'] as String?,
        niveau: j['niveau'] as String?,
        date: j['date'] as String?,
        terrainId: (j['terrain'] as num?)?.toInt(),
      );
}

class Stats {
  const Stats({
    this.terrainsTotal = 0,
    this.transactionsTotal = 0,
    this.litigesOuverts = 0,
    this.alertesActives = 0,
    this.parStatut = const {},
  });

  final int terrainsTotal;
  final int transactionsTotal;
  final int litigesOuverts;
  final int alertesActives;
  final Map<String, int> parStatut;

  factory Stats.fromJson(Map<String, dynamic> j) {
    final statut = j['terrains_par_statut'];
    return Stats(
      terrainsTotal: (j['terrains_total'] as num?)?.toInt() ?? 0,
      transactionsTotal: (j['transactions_total'] as num?)?.toInt() ?? 0,
      litigesOuverts: (j['litiges_ouverts'] as num?)?.toInt() ?? 0,
      alertesActives: (j['alertes_actives'] as num?)?.toInt() ?? 0,
      parStatut: statut is Map
          ? statut.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0))
          : const {},
    );
  }
}

/// Verdict de vérification d'un document (POST /api/documents/verifier/).
class DocumentVerdict {
  const DocumentVerdict({required this.valide, this.message, this.details});

  final bool valide;
  final String? message;
  final Map<String, dynamic>? details;

  factory DocumentVerdict.fromJson(Map<String, dynamic> j) => DocumentVerdict(
        valide: (j['valide'] ?? j['valid'] ?? false) == true,
        message: (j['message'] ?? j['detail']) as String?,
        details: j is Map<String, dynamic> ? j : null,
      );
}
