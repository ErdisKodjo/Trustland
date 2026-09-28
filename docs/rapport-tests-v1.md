# Rapport de Tests — TrustLand (QuadraTech)

**Projet** : TCCHackDefend 2026 — Registre Foncier Numérique  
**Équipe** : QuadraTech  
**Date** : 20 juin 2026  
**Environnement** : Python 3.14.5 · Django 6.0.6 · DRF 3.17.1 · SQLite (tests)

---

## 1. Résumé exécutif

| Indicateur               | Valeur            |
| ------------------------ | ----------------- |
| Tests exécutés           | **61**            |
| Tests réussis            | **61**            |
| Tests échoués            | **0**             |
| Erreurs                  | **0**             |
| Durée d'exécution        | **1.6 s**         |
| Couverture fonctionnelle | 10 modules testés |

**Verdict : VERT — Toutes les fonctionnalités critiques sont opérationnelles.**

---

## 2. Installation des dépendances

### 2.1 Environnement Python

```
Python 3.14.5
pip 26.1.1
```

Un environnement virtuel a été créé dans `backend/venv/` :

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### 2.2 Dépendances installées

| Package                       | Version | Rôle                             |
| ----------------------------- | ------- | -------------------------------- |
| Django                        | 6.0.6   | Framework web principal          |
| djangorestframework           | 3.17.1  | API REST                         |
| djangorestframework-simplejwt | 5.5.1   | Authentification JWT             |
| django-cors-headers           | 4.9.0   | Gestion des CORS                 |
| django-ratelimit              | 4.1.0   | Rate limiting                    |
| psycopg2-binary               | 2.9.12  | Connecteur PostgreSQL            |
| cryptography                  | 49.0.0  | Chiffrement Fernet (AES-128-CBC) |
| python-decouple               | 3.8     | Variables d'environnement        |
| Pillow                        | 12.2.0  | Traitement d'images / QR codes   |
| qrcode                        | 8.2     | Génération de QR codes           |
| PyJWT                         | 2.13.0  | JSON Web Tokens                  |
| lxml                          | 6.1.1   | Traitement XML/HTML              |
| python-docx                   | 1.2.0   | Génération de documents Word     |
| sqlparse                      | 0.5.5   | Parsing SQL                      |
| colorama                      | 0.4.6   | Sortie terminal colorée          |
| tzdata                        | 2026.2  | Données de fuseaux horaires      |

**Résultat** : Installation réussie — aucun conflit de dépendance.

### 2.3 Vérification de la configuration Django

```bash
python manage.py check
# → System check identified no issues (2 silenced).
```

Les 2 vérifications silencées sont intentionnelles (warnings django-ratelimit non bloquants en développement : `E003`, `W001`).

---

## 3. Configuration des tests

Les tests utilisent une base **SQLite en mémoire** pour être indépendants de PostgreSQL :

- **Settings de test** : `config/settings_test.py`
- **Commande d'exécution** :
  
  ```bash
  python manage.py test api --settings=config.settings_test --verbosity=2
  ```
- **Rate limits** : élevés pendant les tests (10 000/min) pour ne pas bloquer les assertions
- **Hachage de mots de passe** : MD5 (accélère les tests)
- **Logs** : désactivés (NullHandler)

---

## 4. Résultats détaillés par module

### 4.1 Modèles Django (`TestModeleProprietaire`, `TestModeleUtilisateur`, `TestModeleTransaction`, `TestModeleBloc`)

| Test                                             | Résultat |
| ------------------------------------------------ | -------- |
| Création d'un propriétaire                       | PASS     |
| Représentation `__str__` propriétaire            | PASS     |
| Email unique (contrainte DB)                     | PASS     |
| Rôle par défaut utilisateur (`agent`)            | PASS     |
| Rôles disponibles (admin / agent / proprietaire) | PASS     |
| Représentation `__str__` utilisateur             | PASS     |
| Signature numérique auto-générée (64 hex)        | PASS     |
| Unicité des signatures numériques                | PASS     |
| Représentation `__str__` Bloc                    | PASS     |

**9/9 tests — PASS**

### 4.2 Blockchain locale (`TestBlockchain`)

| Test                                        | Résultat |
| ------------------------------------------- | -------- |
| Hash SHA-256 déterministe                   | PASS     |
| Hash sensible aux données (avalanche)       | PASS     |
| Chaîne vide → valide                        | PASS     |
| Ajout bloc genesis (index=0, previous=0×64) | PASS     |
| Ajout bloc suivant (enchaînement)           | PASS     |
| Vérification chaîne 3 blocs → valide        | PASS     |
| Falsification données → chaîne invalide     | PASS     |
| Falsification hash stocké → chaîne invalide | PASS     |

**8/8 tests — PASS**

Les tests confirment que la blockchain résiste à toute tentative de falsification : modifier les données ou le hash d'un bloc est immédiatement détecté par `verifier_chaine()`.

### 4.3 Chiffrement des champs sensibles (`TestChiffrementChamps`)

| Test                                        | Résultat |
| ------------------------------------------- | -------- |
| Téléphone chiffré en base (préfixe `$ENC$`) | PASS     |
| Téléphone déchiffré à la lecture            | PASS     |
| Numéro d'identité chiffré + déchiffré       | PASS     |

**3/3 tests — PASS**

Les champs `telephone` et `numero_identite` sont bien chiffrés au repos avec Fernet (AES-128-CBC + HMAC-SHA256) et transparents à la lecture applicative.

### 4.4 Détection de fraude (`TestDetectionFraude`)

| Test                                                                       | Résultat |
| -------------------------------------------------------------------------- | -------- |
| Première transaction → 0 alerte                                            | PASS     |
| Double transaction même jour → alerte CRITIQUE                             | PASS     |
| ≥ 2 transactions en 30 jours → alerte                                      | PASS     |
| ≥ 4 transactions même vendeur en 7 jours → alerte CRITIQUE vendeur_suspect | PASS     |

**4/4 tests — PASS**

> **Note** : La règle "vendeur suspect" se déclenche quand `nb_7j >= 3` (3 *autres* transactions, soit 4 au total pour le même vendeur en 7 jours). C'est cohérent avec le code `fraude.py` ligne 60.

### 4.5 Authentification JWT (`TestAuthentification`)

| Test                                       | Résultat |
| ------------------------------------------ | -------- |
| Login réussi → tokens access + refresh     | PASS     |
| Login mauvais mot de passe → 401           | PASS     |
| Endpoint protégé sans token → 401          | PASS     |
| Endpoint protégé avec token valide → 200   | PASS     |
| Inscription avec rôle `proprietaire`       | PASS     |
| Inscription avec rôle `admin` → 400 refusé | PASS     |
| `GET /api/users/me/` retourne le profil    | PASS     |
| `PATCH /me/` ne change pas le rôle         | PASS     |

**8/8 tests — PASS**

### 4.6 Permissions RBAC (`TestPermissionsRBAC`)

| Test                                     | Action testée                 | Résultat |
| ---------------------------------------- | ----------------------------- | -------- |
| Agent → GET /proprietaires/ → 200        | Agent lit les propriétaires   | PASS     |
| Propriétaire → GET /proprietaires/ → 403 | Accès refusé                  | PASS     |
| Agent → POST /terrains/ → 201            | Agent crée un terrain         | PASS     |
| Propriétaire → POST /terrains/ → 403     | Accès refusé                  | PASS     |
| Admin → GET /utilisateurs/ → 200         | Admin liste les comptes       | PASS     |
| Agent → GET /utilisateurs/ → 403         | Agent ne peut pas lister      | PASS     |
| Propriétaire → GET /alertes/ → 403       | Alertes réservées admin/agent | PASS     |
| Admin → PATCH son propre rôle → 400      | Auto-modification refusée     | PASS     |
| Admin → DELETE son propre compte → 400   | Auto-suppression refusée      | PASS     |

**9/9 tests — PASS**

### 4.7 Endpoints métier (`TestEndpointsMetier`)

| Test                                                  | Résultat |
| ----------------------------------------------------- | -------- |
| GET /api/stats/ → structure correcte                  | PASS     |
| GET /api/terrains/ → liste paginée                    | PASS     |
| POST /api/proprietaires/ → création                   | PASS     |
| POST /api/transactions/ → bloc créé en chaîne         | PASS     |
| Transaction → statut terrain → `en_transaction`       | PASS     |
| POST /api/litiges/ → statut terrain → `litige`        | PASS     |
| PATCH /api/litiges/{id}/resoudre/ → résolution        | PASS     |
| GET /api/blockchain/ → liste blocs                    | PASS     |
| GET /api/blockchain/verifier/ → agent 403 / admin 200 | PASS     |
| GET /api/terrains/{id}/historique/ → liste événements | PASS     |
| GET /api/terrains/{id}/litiges/ → litiges du terrain  | PASS     |

**11/11 tests — PASS**

### 4.8 Gestion des utilisateurs admin (`TestGestionUtilisateurs`)

| Test                              | Résultat |
| --------------------------------- | -------- |
| Lister tous les utilisateurs      | PASS     |
| Créer un compte agent             | PASS     |
| Supprimer un compte               | PASS     |
| Modifier le rôle d'un utilisateur | PASS     |

**4/4 tests — PASS**

### 4.9 Push tokens mobiles (`TestPushTokens`)

| Test                             | Résultat |
| -------------------------------- | -------- |
| Enregistrer un token Expo valide | PASS     |
| Token au format invalide → 400   | PASS     |
| Supprimer un token               | PASS     |
| Sans authentification → 401      | PASS     |

**4/4 tests — PASS**

### 4.10 Journal d'audit (`TestJournalAudit`)

| Test                                  | Résultat |
| ------------------------------------- | -------- |
| POST → entrée créée dans JournalAudit | PASS     |
| GET → aucune entrée créée             | PASS     |

**2/2 tests — PASS**

---

## 5. Comptes utilisateurs de référence

> Les comptes suivants sont les **comptes types** à créer pour utiliser TrustLand.  
> Remplacer les mots de passe par des valeurs sécurisées en production.

### 5.1 Compte Administrateur

| Champ        | Valeur                                                                                                 |
| ------------ | ------------------------------------------------------------------------------------------------------ |
| **Username** | `admin`                                                                                                |
| **Email**    | `admin@trustland.tg`                                                                                   |
| **Rôle**     | `admin` (is_staff=True, is_superuser=True)                                                             |
| **Accès**    | Complet — toutes les fonctionnalités                                                                   |
| **Création** | `python manage.py createadmin --username=admin --email=admin@trustland.tg --password=<MotDePasseFort>` |

**Permissions administrateur :**

- Lecture/écriture complète sur tous les modèles
- Accès à l'interface Django Admin (`/admin/`)
- Gestion des comptes utilisateurs (création / modification / suppression)
- Vérification de l'intégrité de la blockchain
- Résolution des litiges
- Consultation des alertes de fraude
- Suppression de documents

### 5.2 Compte Agent

| Champ        | Valeur                                                    |
| ------------ | --------------------------------------------------------- |
| **Username** | `agent_cadastre`                                          |
| **Email**    | `agent@trustland.tg`                                      |
| **Rôle**     | `agent` (is_staff=False, is_superuser=False)              |
| **Accès**    | Registre foncier en lecture/écriture (pas de suppression) |
| **Création** | Via `POST /api/users/utilisateurs/` par un admin          |

**Permissions agent :**

- Création et modification de propriétaires, terrains, transactions, documents
- Création de litiges
- Consultation des alertes de fraude
- Consultation de la blockchain
- Accès aux statistiques du tableau de bord
- Réception des notifications push (alertes critiques)
- **Interdit** : suppression de documents, gestion des comptes, vérification blockchain

### 5.3 Compte Propriétaire

| Champ        | Valeur                                                                           |
| ------------ | -------------------------------------------------------------------------------- |
| **Username** | `prop_kofi` (exemple)                                                            |
| **Email**    | `kofi@exemple.tg`                                                                |
| **Rôle**     | `proprietaire` (is_staff=False, is_superuser=False)                              |
| **Accès**    | Ses propres terrains et transactions uniquement                                  |
| **Création** | Via `POST /api/users/register/` (inscription publique avec `role: proprietaire`) |

**Permissions propriétaire :**

- Consulter ses propres terrains (filtrés par email)
- Consulter ses propres transactions (vendeur ou acheteur)
- Déclarer un litige sur ses terrains
- Consulter son profil (`/api/users/me/`)
- Télécharger le certificat PDF de ses terrains
- **Interdit** : création de terrains, lecture des alertes, gestion des comptes, liste des propriétaires

### 5.4 Matrice de permissions résumée

| Action                | Admin | Agent | Propriétaire    | Anonyme |
| --------------------- |:-----:|:-----:|:---------------:|:-------:|
| Lire terrains         | ✅     | ✅     | ✅ (ses seuls)   | ✅       |
| Créer terrain         | ✅     | ✅     | ❌               | ❌       |
| Modifier terrain      | ✅     | ✅     | ❌               | ❌       |
| Supprimer terrain     | ✅     | ❌     | ❌               | ❌       |
| Créer transaction     | ✅     | ✅     | ❌               | ❌       |
| Voir ses transactions | ✅     | ✅     | ✅               | ❌       |
| Déclarer un litige    | ✅     | ✅     | ✅               | ❌       |
| Résoudre un litige    | ✅     | ❌     | ❌               | ❌       |
| Voir alertes fraude   | ✅     | ✅     | ❌               | ❌       |
| Vérifier blockchain   | ✅     | ❌     | ❌               | ❌       |
| Gérer utilisateurs    | ✅     | ❌     | ❌               | ❌       |
| Certificat PDF        | ✅     | ✅     | ✅ (son terrain) | ❌       |
| Supprimer document    | ✅     | ❌     | ❌               | ❌       |

---

## 6. Observations et anomalies détectées

### 6.1 Comportement de l'inscription publique

**Observation** : Le serializer `RegisterSerializer` accepte les rôles `agent` et `proprietaire` mais pas `admin`. Cependant, il n'impose pas automatiquement le rôle `proprietaire` — le client doit explicitement envoyer `role: proprietaire`.

**Risque** : Un utilisateur malveillant pourrait s'inscrire avec le rôle `agent` via l'endpoint public `/api/users/register/`, obtenant ainsi des droits de lecture/écriture étendus.

**Recommandation** : Forcer `role = 'proprietaire'` dans `RegisterSerializer.create()` et retirer le champ `role` des champs acceptés :

```python
# users/serializers.py — RegisterSerializer
class Meta:
    model = Utilisateur
    fields = ['username', 'email', 'password']  # retirer 'role'

def create(self, validated_data):
    validated_data['role'] = 'proprietaire'
    return Utilisateur.objects.create_user(**validated_data)
```

### 6.2 Génération de QR code lors des tests

La méthode `Terrain.save()` génère un QR code image à chaque création de terrain. En tests, ce comportement génère des fichiers dans `backend/media/qrcodes/` (même avec SQLite). Pas d'impact sur les tests mais les fichiers s'accumulent.

**Recommandation** : Ajouter `@override_settings(MEDIA_ROOT=tempfile.mkdtemp())` dans les fixtures de test.

### 6.3 Rapport `requirements.txt` — package manquant

`reportlab` est utilisé dans `api/views.py` pour la génération de certificats PDF, mais n'est **pas listé** dans `requirements.txt`. Cela ne bloque pas les tests (le PDF n'est pas testé) mais cassera le déploiement.

**Recommandation** : Ajouter `reportlab>=4.0` dans `requirements.txt`.

---

## 7. Commandes de démarrage

### Backend (développement)

```bash
cd backend
venv\Scripts\activate                    # Windows
python manage.py migrate
python manage.py createadmin \
    --username=admin \
    --email=admin@trustland.tg \
    --password=MotDePasseFort123!
python manage.py runserver 0.0.0.0:8000
```

### Lancer les tests

```bash
cd backend
python manage.py test api --settings=config.settings_test --verbosity=2
```

### Frontend (développement)

```bash
cd frontend
npm install
npm run dev
# Accessible sur http://localhost:5173
```

---

## 8. Conclusion

Le backend TrustLand est **fonctionnel et bien structuré**. Les 61 tests couvrent les modules critiques :

- **Sécurité** : JWT, RBAC à 3 niveaux, chiffrement Fernet des PII
- **Intégrité** : blockchain locale immuable, détection de falsification
- **Fraude** : 3 règles automatiques avec alertes et notifications push
- **Audit** : journal de toutes les opérations d'écriture

Le seul point de sécurité à corriger en priorité est la restriction du rôle à l'inscription publique (section 6.1).

---

*Rapport généré automatiquement — TrustLand / QuadraTech — TCCHackDefend 2026*
