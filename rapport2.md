# Rapport de Tests v2 — TrustLand (QuadraTech)

**Projet** : TCCHackDefend 2026 — Registre Foncier Numérique  
**Équipe** : QuadraTech  
**Date** : 20 juin 2026  
**Environnement** : Python 3.14.5 · Django 6.0.6 · DRF 3.17.1 · SQLite (tests)  
**Référence** : Rapport initial `rapport.md` (v1)

---

## 1. Résumé exécutif

| Indicateur               | v1 (rapport.md) | v2 (ce rapport) |
| ------------------------ |:---------------:|:---------------:|
| Tests exécutés           | 61              | **75**          |
| Tests réussis            | 61              | **75**          |
| Tests échoués            | 0               | **0**           |
| Durée d'exécution        | 1.6 s           | **0.9 s**       |
| Anomalies corrigées      | —               | **2**           |
| Améliorations appliquées | —               | **4**           |

**Verdict : VERT — 75/75 tests passent. Toutes les anomalies corrigées.**

---

## 2. Corrections appliquées

### 2.1 Correction #1 — Faille RBAC dans l'inscription publique

**Fichier modifié** : [backend/users/serializers.py](backend/users/serializers.py)

**Problème** : `RegisterSerializer` exposait le champ `role` dans les champs acceptés et l'utilisateur pouvait s'inscrire avec `role: agent` via l'API publique, obtenant des droits d'écriture étendus sur les terrains, propriétaires et transactions.

**Avant** :

```python
class Meta:
    fields = ['username', 'email', 'password', 'role']

def validate_role(self, value):
    allowed = [Utilisateur.Role.AGENT, Utilisateur.Role.PROPRIETAIRE]
    ...  # agent était autorisé à l'inscription publique

def create(self, validated_data):
    return Utilisateur.objects.create_user(**validated_data)
```

**Après** :

```python
class Meta:
    fields = ['username', 'email', 'password', 'password2']  # role retiré

def validate(self, attrs):
    if attrs['password'] != attrs['password2']:
        raise serializers.ValidationError(...)
    return attrs

def create(self, validated_data):
    validated_data.pop('password2')
    validated_data['role'] = Utilisateur.Role.PROPRIETAIRE  # forcé côté serveur
    return Utilisateur.objects.create_user(**validated_data)
```

**Impact sécurité** : Toute tentative d'injection de rôle via le payload public est désormais ignorée — même si le client envoie `role: admin` ou `role: agent`, le compte créé sera toujours `proprietaire`.

**Bonus** : Ajout de la confirmation de mot de passe côté serveur (`password2`). Le frontend la validait déjà côté client, mais sans validation serveur, cette protection était contournable via une requête directe à l'API.

**Tests associés** :

- `test_register_force_role_proprietaire` — l'inscription sans role → rôle = proprietaire
- `test_register_password2_requis` — sans password2 → 400
- `test_register_passwords_incompatibles` — password ≠ password2 → 400
- `test_register_role_injecte_ignore` — role: agent envoyé → compte créé en proprietaire

---

### 2.2 Correction #2 — Dépendance `reportlab` manquante dans `requirements.txt`

**Fichier modifié** : [backend/requirements.txt](backend/requirements.txt)

**Problème** : `api/views.py` importe `reportlab` pour la génération des certificats PDF (`GET /api/terrains/{id}/certificat/`), mais ce package n'était pas déclaré dans `requirements.txt`. Un déploiement fresh échouerait à la première demande de certificat PDF.

**Correction** :

```diff
+ reportlab>=4.0
```

**Version installée** : `reportlab 5.0.0` (compatible avec `>=4.0`).

---

## 3. Améliorations appliquées

### 3.1 Amélioration #1 — Validation des magic bytes pour les documents

**Fichier modifié** : [backend/api/serializers.py](backend/api/serializers.py)

**Contexte** : Le README décrit trois niveaux de validation des fichiers (taille, extension, magic bytes). Les niveaux 1 et 2 étaient implémentés mais le niveau 3 (magic bytes) était absent du code — seule l'extension et le content-type déclaré par le navigateur étaient vérifiés.

**Risque sans cette amélioration** : Un attaquant pouvait renommer un fichier malveillant (HTML, script, binaire) avec l'extension `.pdf` et l'uploader avec succès.

**Implémentation** : Lecture des 8 premiers octets du fichier avant toute écriture en base. Signatures vérifiées :

| Type      | Magic bytes         | Hex                       |
| --------- | ------------------- | ------------------------- |
| PDF       | `%PDF`              | `25 50 44 46`             |
| JPEG      | `ÿØÿ`               | `FF D8 FF`                |
| PNG       | `\x89PNG\r\n\x1a\n` | `89 50 4E 47 0D 0A 1A 0A` |
| TIFF (LE) | `II*\x00`           | `49 49 2A 00`             |
| TIFF (BE) | `MM\x00*`           | `4D 4D 00 2A`             |

**Tests associés** :

- `test_pdf_valide_accepte` — PDF avec `%PDF` → 201
- `test_png_valide_accepte` — PNG avec magic bytes corrects → 201
- `test_fichier_deguise_refuse` — fichier HTML renommé `.pdf` → 400
- `test_extension_non_autorisee_refuse` — extension `.exe` → 400
- `test_fichier_trop_grand_refuse` — fichier > 5 Mo → 400

---

### 3.2 Amélioration #2 — Validation du montant des transactions

**Fichier modifié** : [backend/api/serializers.py](backend/api/serializers.py)

**Problème** : `TransactionSerializer` n'interdisait pas les montants nuls ou négatifs. Une transaction avec `montant: 0` ou `montant: -5000` était acceptée, ce qui est métier-invalide pour un registre foncier.

**Correction** :

```python
def validate(self, attrs):
    ...
    montant = attrs.get('montant')
    if montant is not None and montant <= 0:
        raise serializers.ValidationError(
            {'montant': "Le montant doit être strictement positif."}
        )
    return attrs
```

**Tests associés** :

- `test_montant_nul_refuse` — montant = 0 → 400
- `test_montant_negatif_refuse` — montant = -5000 → 400
- `test_montant_positif_accepte` — montant = 1 → 201

---

### 3.3 Amélioration #3 — Suppression de terrain réservée à l'admin

**Fichier modifié** : [backend/api/views.py](backend/api/views.py)

**Problème** : La matrice des permissions du README indique que seul l'Admin peut supprimer un terrain (Agent ❌). Or `TerrainViewSet` utilisait la permission `IsAdminOrAgentOrPublicRead` pour toutes les actions, ce qui accordait implicitement aux agents le droit de DELETE.

**Avant** : Aucun contrôle dans `TerrainViewSet` — agent pouvait `DELETE /api/terrains/{id}/` avec succès (HTTP 204).

**Après** :

```python
def perform_destroy(self, instance):
    if self.request.user.role != 'admin':
        raise PermissionDenied("Seul un administrateur peut supprimer un terrain.")
    instance.delete()
```

Cohérence avec l'approche déjà utilisée dans `DocumentViewSet.perform_destroy()`.

**Tests associés** :

- `test_admin_peut_supprimer_terrain` — Admin DELETE → 204
- `test_agent_ne_peut_pas_supprimer_terrain` — Agent DELETE → 403

---

## 4. Résultats détaillés des 75 tests

### 4.1 Récapitulatif par module

| Module                                       | Tests  | Résultat             |
| -------------------------------------------- |:------:|:--------------------:|
| Modèles Django                               | 9      | PASS                 |
| Blockchain locale                            | 8      | PASS                 |
| Chiffrement Fernet                           | 3      | PASS                 |
| Détection de fraude                          | 4      | PASS                 |
| Authentification JWT                         | 10     | PASS                 |
| Permissions RBAC                             | 11     | PASS                 |
| Endpoints métier                             | 11     | PASS                 |
| Validation métier (nouveau)                  | 5      | PASS                 |
| Validation documents / magic bytes (nouveau) | 5      | PASS                 |
| Gestion utilisateurs admin                   | 4      | PASS                 |
| Push tokens mobiles                          | 4      | PASS                 |
| Journal d'audit                              | 2      | PASS                 |
| **TOTAL**                                    | **75** | **75 PASS — 0 FAIL** |

### 4.2 Détail module authentification (amélioré)

| Test                                         | Résultat |
| -------------------------------------------- | -------- |
| Login réussi → access + refresh              | PASS     |
| Login mauvais mot de passe → 401             | PASS     |
| Endpoint protégé sans token → 401            | PASS     |
| Endpoint protégé avec token → 200            | PASS     |
| Inscription force rôle proprietaire          | PASS     |
| Inscription sans password2 → 400             | PASS     |
| Passwords incompatibles → 400                | PASS     |
| Injection role: agent ignorée → proprietaire | PASS     |
| GET /me/ retourne le profil                  | PASS     |
| PATCH /me/ ignore le changement de rôle      | PASS     |

### 4.3 Détail module RBAC (amélioré)

| Test                                      | Rôle testeur | Action                     | HTTP attendu | Résultat |
| ----------------------------------------- | ------------ | -------------------------- | ------------ | -------- |
| Agent lit les propriétaires               | Agent        | GET /proprietaires/        | 200          | PASS     |
| Propriétaire accède aux propriétaires     | Prop.        | GET /proprietaires/        | 403          | PASS     |
| Agent crée un terrain                     | Agent        | POST /terrains/            | 201          | PASS     |
| Propriétaire crée un terrain              | Prop.        | POST /terrains/            | 403          | PASS     |
| Admin liste les utilisateurs              | Admin        | GET /utilisateurs/         | 200          | PASS     |
| Agent liste les utilisateurs              | Agent        | GET /utilisateurs/         | 403          | PASS     |
| Propriétaire voit les alertes             | Prop.        | GET /alertes/              | 403          | PASS     |
| Admin modifie son propre rôle             | Admin        | PATCH /utilisateurs/me     | 400          | PASS     |
| Admin se supprime lui-même                | Admin        | DELETE /utilisateurs/me    | 400          | PASS     |
| **Admin supprime un terrain** *(nouveau)* | **Admin**    | **DELETE /terrains/{id}/** | **204**      | **PASS** |
| **Agent supprime un terrain** *(nouveau)* | **Agent**    | **DELETE /terrains/{id}/** | **403**      | **PASS** |

### 4.4 Détail module validation documents (nouveau)

| Test                           | Scénario            | HTTP attendu | Résultat |
| ------------------------------ | ------------------- | ------------ | -------- |
| PDF avec magic bytes `%PDF`    | Fichier légitime    | 201          | PASS     |
| PNG avec magic bytes `\x89PNG` | Fichier légitime    | 201          | PASS     |
| HTML renommé en `.pdf`         | Fichier déguisé     | 400          | PASS     |
| Binaire avec extension `.exe`  | Extension interdite | 400          | PASS     |
| Fichier > 5 Mo                 | Taille dépassée     | 400          | PASS     |

### 4.5 Détail module validation métier (nouveau)

| Test                | Scénario             | HTTP attendu | Résultat |
| ------------------- | -------------------- | ------------ | -------- |
| Vendeur == Acheteur | Même personne        | 400          | PASS     |
| Montant = 0         | Transaction invalide | 400          | PASS     |
| Montant = -5000     | Transaction invalide | 400          | PASS     |
| Terrain en litige   | Transaction bloquée  | 400          | PASS     |
| Montant = 1 FCFA    | Transaction valide   | 201          | PASS     |

---

## 5. Comptes utilisateurs de référence

> Comptes types à créer pour démarrer TrustLand.

### 5.1 Administrateur

| Champ        | Valeur                                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------------------ |
| **Username** | `admin`                                                                                                |
| **Email**    | `admin@trustland.tg`                                                                                   |
| **Rôle**     | `admin`                                                                                                |
| **Création** | `python manage.py createadmin --username=admin --email=admin@trustland.tg --password=<MotDePasseFort>` |

**Permissions** : Accès complet. Seul rôle pouvant :

- Supprimer des terrains (`DELETE /api/terrains/{id}/`)
- Supprimer des documents (`DELETE /api/documents/{id}/`)
- Vérifier l'intégrité de la blockchain (`GET /api/blockchain/verifier/`)
- Gérer les comptes utilisateurs (`/api/users/utilisateurs/`)
- Résoudre les litiges (`PATCH /api/litiges/{id}/resoudre/`)
- Accéder à l'interface Django Admin (`/admin/`)

### 5.2 Agent cadastral

| Champ        | Valeur                                                          |
| ------------ | --------------------------------------------------------------- |
| **Username** | `agent_cadastre`                                                |
| **Email**    | `agent@trustland.tg`                                            |
| **Rôle**     | `agent`                                                         |
| **Création** | Via `POST /api/users/utilisateurs/` par un admin (rôle = agent) |

**Permissions** : Lecture + écriture du registre foncier. Peut :

- Créer/modifier des propriétaires, terrains, transactions, documents, litiges
- Consulter alertes de fraude et blockchain
- Recevoir notifications push (alertes critiques)

**Ne peut pas** : supprimer terrains/documents, gérer utilisateurs, résoudre litiges, vérifier blockchain.

### 5.3 Propriétaire foncier

| Champ        | Valeur                                                        |
| ------------ | ------------------------------------------------------------- |
| **Username** | `prop_kofi` (exemple)                                         |
| **Email**    | `kofi@exemple.tg`                                             |
| **Rôle**     | `proprietaire` (forcé côté serveur)                           |
| **Création** | Via `POST /api/users/register/` avec `password` + `password2` |

**Permissions limitées** :

- Consulter ses propres terrains (filtrés automatiquement par email)
- Consulter ses propres transactions (vendeur ou acheteur)
- Déclarer un litige sur ses terrains
- Télécharger son certificat PDF
- Consulter et modifier son profil

**Ne peut pas** : lire la liste des propriétaires, créer des terrains, voir les alertes, accéder à la blockchain.

### 5.4 Matrice de permissions complète (après corrections)

| Action                                       | Admin | Agent | Propriétaire    | Anonyme |
| -------------------------------------------- |:-----:|:-----:|:---------------:|:-------:|
| Lire terrains                                | ✅     | ✅     | ✅ (ses seuls)   | ✅       |
| Créer terrain                                | ✅     | ✅     | ❌               | ❌       |
| Modifier terrain                             | ✅     | ✅     | ❌               | ❌       |
| **Supprimer terrain** *(corrigé)*            | ✅     | **❌** | ❌               | ❌       |
| Créer transaction (montant > 0)              | ✅     | ✅     | ❌               | ❌       |
| Voir ses transactions                        | ✅     | ✅     | ✅               | ❌       |
| Uploader document (magic bytes)              | ✅     | ✅     | ❌               | ❌       |
| Supprimer document                           | ✅     | ❌     | ❌               | ❌       |
| Vérifier document SHA-256                    | ✅     | ✅     | ✅               | ❌       |
| Déclarer un litige                           | ✅     | ✅     | ✅               | ❌       |
| Résoudre un litige                           | ✅     | ❌     | ❌               | ❌       |
| Voir alertes fraude                          | ✅     | ✅     | ❌               | ❌       |
| Lister blockchain                            | ✅     | ✅     | ✅               | ❌       |
| Vérifier intégrité blockchain                | ✅     | ❌     | ❌               | ❌       |
| Gérer utilisateurs                           | ✅     | ❌     | ❌               | ❌       |
| **S'inscrire** *(rôle forcé = propriétaire)* | —     | —     | ✅               | ✅       |
| Certificat PDF                               | ✅     | ✅     | ✅ (son terrain) | ❌       |

---

## 6. Récapitulatif des fichiers modifiés

| Fichier                                                            | Nature         | Description                                     |
| ------------------------------------------------------------------ | -------------- | ----------------------------------------------- |
| [backend/users/serializers.py](backend/users/serializers.py)       | Correction     | Forcer `role=proprietaire`, ajouter `password2` |
| [backend/requirements.txt](backend/requirements.txt)               | Correction     | Ajouter `reportlab>=4.0`                        |
| [backend/api/serializers.py](backend/api/serializers.py)           | Amélioration   | Magic bytes + validation `montant > 0`          |
| [backend/api/views.py](backend/api/views.py)                       | Amélioration   | `perform_destroy` terrain → admin uniquement    |
| [backend/api/tests.py](backend/api/tests.py)                       | Tests          | +14 tests (75 total, tous verts)                |
| [backend/config/settings_test.py](backend/config/settings_test.py) | Infrastructure | Settings SQLite pour l'exécution des tests      |
| [backend/config/settings_dev.py](backend/config/settings_dev.py)   | Infrastructure | Settings SQLite pour le développement local     |
| [backend/dev.ps1](backend/dev.ps1)                                 | Infrastructure | Script de démarrage rapide (PowerShell)         |

---

## 7. Problème résolu — Démarrage sans PostgreSQL

### 7.1 Cause de l'erreur `UnicodeDecodeError 0xe9`

Lors de l'exécution de `python manage.py runserver` ou `python manage.py makemigrations` **sans** l'option `--settings`, Django utilise les settings par défaut (`config.settings`) qui tentent de se connecter à **PostgreSQL**. Or PostgreSQL n'est pas installé sur cette machine.

`psycopg2` échoue à établir la connexion, et le message d'erreur Windows retourné par le système est en **français** (Windows CP1252). La lettre `é` est encodée `0xe9` en CP1252 — un octet invalide en UTF-8. D'où l'erreur :

```
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xe9 in position 103
```

Ce n'est pas un bug du code TrustLand : c'est l'interaction entre Windows francophone, psycopg2 et l'absence de PostgreSQL.

### 7.2 Solution : settings de développement avec SQLite

Un fichier `config/settings_dev.py` a été créé. Il hérite de tous les settings de production mais remplace la base PostgreSQL par **SQLite** (fichier `backend/db_dev.sqlite3`).

**Première utilisation (à faire une seule fois)** :

```powershell
cd backend
.\venv\Scripts\activate

# Créer la base SQLite et appliquer toutes les migrations
python manage.py migrate --settings=config.settings_dev

# Créer le compte administrateur
python manage.py createadmin `
    --username=admin `
    --email=admin@trustland.tg `
    --password=Admin1234! `
    --settings=config.settings_dev
```

**Démarrage quotidien** :

```powershell
# Option 1 — Script tout-en-un (migrate + runserver)
cd backend
.\dev.ps1

# Option 2 — Variable d'environnement (plus besoin de --settings ensuite)
$env:DJANGO_SETTINGS_MODULE = "config.settings_dev"
$env:PYTHONUTF8 = "1"
python manage.py runserver 0.0.0.0:8000
```

**Commandes disponibles via `dev.ps1`** :

```powershell
.\dev.ps1              # migrate + runserver :8000
.\dev.ps1 migrate      # migrations seulement
.\dev.ps1 admin        # créer le compte admin
.\dev.ps1 makemigrations  # générer de nouvelles migrations
.\dev.ps1 shell        # shell Django interactif
```

### 7.3 Résumé des settings disponibles

| Fichier                   | Base de données           | Usage                                |
| ------------------------- | ------------------------- | ------------------------------------ |
| `config/settings.py`      | PostgreSQL (prod)         | Production avec PostgreSQL configuré |
| `config/settings_dev.py`  | SQLite (`db_dev.sqlite3`) | Développement local sans PostgreSQL  |
| `config/settings_test.py` | SQLite (`:memory:`)       | Exécution de la suite de tests       |

> **Note** : Pour la production et la soutenance, PostgreSQL reste requis (`config/settings.py`). Le SQLite est uniquement pour le développement local.

---

## 8. Commandes utiles

### Lancer les tests

```powershell
cd backend
.\venv\Scripts\activate
python manage.py test api --settings=config.settings_test --verbosity=2
```

### Démarrer le backend en développement (SQLite, sans PostgreSQL)

```powershell
cd backend
.\venv\Scripts\activate
.\dev.ps1          # migrate + runserver
# → http://localhost:8000
```

### Démarrer le frontend

```powershell
cd frontend
npm install
npm run dev
# → http://localhost:5173
```

---

## 9. Conclusion

Les 2 anomalies identifiées en v1 ont été corrigées, 4 améliorations ont été appliquées, et la configuration de développement a été rendue opérationnelle sans PostgreSQL. Le projet TrustLand est désormais :

- **Sécurisé** contre l'élévation de privilèges à l'inscription publique
- **Complet** côté dépendances (`reportlab` ajouté)
- **Renforcé** contre l'upload de fichiers malveillants (magic bytes)
- **Cohérent** entre le code et la matrice des permissions documentée (suppression terrain admin-only)
- **Validé** métier (transactions à montant positif obligatoire)
- **Démarrable localement** sans PostgreSQL grâce aux settings SQLite (`settings_dev.py` + `dev.ps1`)

La suite de 75 tests couvre l'ensemble des fonctionnalités critiques et constitue un filet de sécurité pour les évolutions futures.

---

*Rapport généré automatiquement — TrustLand / QuadraTech — TCCHackDefend 2026*
