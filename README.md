# TrustLand — Registre Foncier Numérique

> Plateforme de gestion et de traçabilité des droits fonciers pour la République du Togo.
> **Sécurité. Confiance. Traçabilité.** — équipe QuadraTech, TCCHackDefend 2026.

TrustLand numérise l'enregistrement des terrains, la chaîne des transactions, la détection
de fraude et la certification PDF avec QR code — le tout sécurisé par une blockchain locale
et un chiffrement des données sensibles.

![Python](https://img.shields.io/badge/Python-3.12+-3776AB?logo=python&logoColor=white)
![Django](https://img.shields.io/badge/Django-6.0-092E20?logo=django&logoColor=white)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)
![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter&logoColor=white)
![License](https://img.shields.io/badge/Usage-Académique-lightgrey)

---

## Sommaire

1. [Architecture](#1-architecture)
2. [Structure du dépôt](#2-structure-du-dépôt)
3. [Démarrage rapide](#3-démarrage-rapide)
4. [Variables d'environnement](#4-variables-denvironnement)
5. [API REST](#5-api-rest)
6. [Rôles et permissions](#6-rôles-et-permissions)
7. [Sécurité](#7-sécurité)
8. [Blockchain et détection de fraude](#8-blockchain-et-détection-de-fraude)
9. [Design system](#9-design-system)
10. [Tests](#10-tests)
11. [Contexte académique](#11-contexte-académique)

---

## 1. Architecture

| Couche | Stack | Rôle |
|---|---|---|
| Backend | Django 6 + DRF 3.17, PostgreSQL, JWT (SimpleJWT) | API métier, blockchain, fraude, certificats PDF |
| Frontend | React 19 + Vite, Leaflet, Recharts | Application web d'administration du registre |
| Mobile | **Flutter** (Material 3, design system « Cadastre ») | Inscription, consultation terrain, scan QR, hors-ligne, biométrie, push FCM |

```
┌──────────────────────────────────────────────────────┐
│                       Clients                         │
│   Navigateur (React 19)   │   Mobile (Flutter M3)     │
│   Cookie httpOnly JWT      │   Bearer + Keystore/      │
│                            │   Keychain                │
└────────────┬──────────────┴──────────────┬───────────┘
             │ HTTPS / CORS                 │ HTTPS
             ▼                              ▼
┌──────────────────────────────────────────────────────┐
│              Django 6 + DRF 3.17   [:8000]            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │  App users  │  │   App api    │  │  Middleware  │  │
│  │  JWT auth   │  │  Métier +    │  │  AuditLog   │  │
│  │  RBAC       │  │  Blockchain  │  │  CORS / CSRF│  │
│  └─────────────┘  └──────────────┘  └─────────────┘  │
└───────────────────────────┬──────────────────────────┘
                            │
             ┌──────────────┴──────────────┐
             ▼                             ▼
    ┌────────────────┐           ┌──────────────────┐
    │  PostgreSQL    │           │  Système de       │
    │  trustland_db  │           │  fichiers media/  │
    │  (Fernet enc.) │           │  (QR codes, PDF)  │
    └────────────────┘           └──────────────────┘
```

En développement, le frontend proxifie `/api/*` et `/media/*` vers le backend via Vite.
Le mobile contacte directement le backend via l'IP réseau locale (voir `mobile/lib/core/config.dart`).

## 2. Structure du dépôt

```
Trustland/
├── backend/          Django REST Framework + PostgreSQL
│   ├── api/          Modèles, vues, serializers, blockchain, fraude
│   ├── users/        Utilisateur personnalisé (rôles), authentification
│   ├── config/       Settings (prod / dev / test), URLs racine
│   └── manage.py
├── frontend/         React 19 + Vite (CSS custom — design system « Cadastre »)
│   └── src/
│       ├── components/   Navbar, formulaires, icônes partagées (icons.jsx)
│       ├── pages/        15 écrans (registre, carte, blockchain, litiges…)
│       ├── context/      AuthContext (session, refresh proactif)
│       └── assets/       Logo, plan cadastral du hero
├── mobile/           Flutter Material 3 — design system « Cadastre » partagé
│   └── lib/          core (thème, réseau JWT), screens, widgets, state
└── docs/             Cahiers des charges, rapports de tests, visuels
```

## 3. Démarrage rapide

Prérequis : Python 3.12+, Node.js 20 LTS+, PostgreSQL 14+ (Redis 7+ optionnel en dev, requis en production multi-workers).

### 3.1 Backend (Django)

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux / macOS

pip install -r requirements.txt

# Créer la base PostgreSQL (une fois)
psql -U postgres -c "CREATE DATABASE trustland_db;"
psql -U postgres -c "CREATE USER trustland_user WITH PASSWORD 'mot-de-passe-fort';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE trustland_db TO trustland_user;"

# Configurer les secrets (copier puis compléter)
cp .env.example .env

# Sans PostgreSQL disponible, un mode dev SQLite existe :
#   python manage.py migrate --settings=config.settings_dev
#   python manage.py runserver --settings=config.settings_dev

python manage.py migrate
python manage.py createadmin          # administrateur de démonstration
python manage.py runserver 0.0.0.0:8000
```

### 3.2 Frontend (React / Vite)

```bash
cd frontend
npm install
npm run dev          # http://localhost:5173 — proxifie /api vers :8000
```

### 3.3 Mobile (Flutter) — optionnel

Prérequis : Flutter SDK ≥ 3.22 (`flutter doctor` sans erreur).

```bash
cd mobile
flutter pub get
# Génère android/ + ios/ localement (non versionnés), puis ajoutez
# les permissions listées dans mobile/README.md :
flutter create . --org com.trustland --project-name trustland_mobile \
    --platforms android,ios
# Renseigner l'IP du backend dans lib/core/config.dart
flutter run
```

Détails complets (permissions, architecture, équivalences Expo → Flutter) :
[`mobile/README.md`](mobile/README.md).

**Ordre de démarrage** : PostgreSQL → Backend (:8000) → Frontend (:5173) et/ou Mobile.

## 4. Variables d'environnement

Tous les secrets vivent dans `backend/.env` (**jamais versionné** — voir `backend/.env.example`).

| Variable | Obligatoire | Description |
|---|---|---|
| `SECRET_KEY` | ✅ | Clé secrète Django (`get_random_secret_key()`) |
| `DEBUG` | ✅ | `True` en dev, **`False` en production** |
| `ALLOWED_HOSTS` | ✅ | Hôtes autorisés, séparés par virgules |
| `CORS_ALLOWED_ORIGINS` | ✅ | Origines frontend (`http://localhost:5173`) |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | ✅ | Accès PostgreSQL |
| `DB_HOST` / `DB_PORT` | — | Par défaut `localhost:5432` |
| `FIELD_ENCRYPTION_KEY` | ✅ | Clé Fernet (chiffrement téléphone + pièce d'identité) |
| `SITE_URL` | ✅ | URL publique intégrée dans les QR codes |
| `REDIS_URL` | prod | Rate-limiting multi-workers (vide en dev → LocMemCache) |

> ⚠️ Changer `FIELD_ENCRYPTION_KEY` invalide toutes les données chiffrées existantes en base.

## 5. API REST

Authentification : JWT en cookies `httpOnly` (navigateur) **ou** header `Authorization: Bearer` (mobile).
Access token 60 min, refresh 24 h ; renouvellement proactif côté frontend.

### Authentification

| Méthode | URL | Description | Accès |
|---|---|---|---|
| POST | `/api/token/` | Connexion (cookies httpOnly) | Public |
| POST | `/api/token/refresh/` | Renouvelle l'access token | Public |
| POST | `/api/users/logout/` | Invalide le refresh + cookies | Authentifié |
| POST | `/api/users/register/` | Inscription (rôle `proprietaire` uniquement) | Public |
| GET/PATCH | `/api/users/me/` | Profil courant | Authentifié |
| POST | `/api/users/changer-mot-de-passe/` | Changement de mot de passe | Authentifié |

### Registre foncier

| Méthode | URL | Description | Accès |
|---|---|---|---|
| GET/POST | `/api/proprietaires/` | Propriétaires | Admin, Agent |
| GET | `/api/terrains/` | Liste filtrée par rôle | Authentifié |
| POST | `/api/terrains/` | Création (QR auto-généré) | Admin, Agent |
| GET | `/api/terrains/<id>/certificat/` | Certificat PDF | Selon rôle |
| GET | `/api/terrains/<id>/historique/` | Timeline chronologique | Authentifié |
| GET/POST | `/api/documents/` | Documents fonciers | Admin, Agent |
| POST | `/api/documents/verifier/` | Vérification SHA-256 | Authentifié |
| GET/POST | `/api/transactions/` | Transactions | Admin, Agent |
| GET/POST | `/api/litiges/` | Litiges (déclarables par propriétaire) | Authentifié |
| PATCH | `/api/litiges/<id>/resoudre/` | Résolution officielle | Admin |
| GET | `/api/alertes/` | Alertes de fraude | Admin, Agent |
| GET | `/api/blockchain/` | Blocs de la chaîne | Authentifié |
| GET | `/api/blockchain/verifier/` | Vérification d'intégrité | Admin |
| GET | `/api/stats/` | Statistiques du dashboard | Authentifié |

## 6. Rôles et permissions

RBAC à 3 niveaux synchronisé avec les flags Django natifs (`is_staff`, `is_superuser`) par signal.

| Action | Admin | Agent | Propriétaire | Anonyme |
|---|:---:|:---:|:---:|:---:|
| Lire terrains | ✅ | ✅ | ✅ | ✅ |
| Créer / modifier terrain | ✅ | ✅ | ❌ | ❌ |
| Supprimer terrain | ✅ | ❌ | ❌ | ❌ |
| Créer transaction | ✅ | ✅ | ❌ | ❌ |
| Déclarer un litige | ✅ | ✅ | ✅ | ❌ |
| Voir alertes fraude | ✅ | ✅ | ❌ | ❌ |
| Gestion des utilisateurs | ✅ | ❌ | ❌ | ❌ |

L'inscription publique crée uniquement des comptes `proprietaire` ; les comptes
`agent` et `admin` sont créés par un administrateur (`python manage.py createadmin`).

## 7. Sécurité

- **JWT httpOnly** — jamais de token dans `localStorage` (anti-XSS) ; classe `CookieJWTAuthentication` hybride (cookie navigateur / header mobile).
- **Chiffrement Fernet** (AES-128-CBC + HMAC) des champs sensibles `telephone` et `numero_identite` via un `EncryptedField` personnalisé.
- **Rate limiting** : login 5/min, anonyme 20/min, utilisateur 200/min, transactions 30/h (Redis en production).
- **En-têtes HTTPS** en production : HSTS 1 an, redirection SSL, cookies `Secure`, `X-Frame-Options: DENY`, `nosniff`.
- **Validation des uploads** : contrôle des magic bytes côté serializers.
- **Piste d'audit** : `AuditLogMiddleware` journalise les actions sensibles dans `logs/security.log` (rotatif 5 Mo × 5, non versionné).

## 8. Blockchain et détection de fraude

**Blockchain locale** — chaque transaction est horodatée dans un bloc SHA-256 chaîné au précédent
(`blockchain.py` : `ajouter_bloc` / `verifier_chaine`). L'intégrité complète de la chaîne est
vérifiable depuis l'interface (`GET /api/blockchain/verifier/`).

**Détection automatique** (`fraude.py`, 3 règles déclenchant une `Alerte`) :
1. **Double vente** — un terrain libre fait l'objet de plusieurs transactions ;
2. **Cession répétée suspecte** — nombre anormal de cessions sur une courte période ;
3. **Vente simultanée** — transactions concurrentes sur le même terrain.

## 9. Design system

Le frontend applique un design system interne **« Cadastre »** — langage visuel trust-first
institutionnel, aligné sur l'identité du logo (vert + bleu) :

- **Palette Forest** : vert profond `#1e5a31` (primaire), neutres sauge/os, accent ambre `#b45309` (alertes), bleu harmonisé `#1d5c96` (information) ;
- **Typographie** : Outfit Variable (auto-hébergée via Fontsource) ;
- **Rayons verrouillés** : contrôles 10 px, cartes 14 px, badges en pilule ;
- **États complets** : survol, focus visible, appui (`translateY`), squelettes de chargement, états vides ;
- **Accessibilité** : contrastes WCAG AA, `prefers-reduced-motion` respecté, navigation clavier ;
- **Responsive** : replis explicites à 1024 / 880 / 640 px.

Les tokens sont centralisés dans [`frontend/src/index.css`](frontend/src/index.css) ;
les icônes (famille unique Heroicons outline) dans [`frontend/src/components/icons.jsx`](frontend/src/components/icons.jsx).

Le mobile Flutter applique **la même palette et les mêmes rayons** (thème Material 3
construit manuellement dans [`mobile/lib/core/theme/app_theme.dart`](mobile/lib/core/theme/app_theme.dart)) —
une seule identité visuelle sur le web et sur mobile.

## 10. Tests

75 tests unitaires et fonctionnels (10 modules) — verdict complet dans [`docs/rapport-tests-v2.md`](docs/rapport-tests-v2.md)
(v1 : [`docs/rapport-tests-v1.md`](docs/rapport-tests-v1.md)).

```bash
cd backend
python manage.py test --settings=config.settings_test
```

## 11. Contexte académique

Projet réalisé dans le cadre du hackathon **TCCHackDefend 2026** par l'équipe **QuadraTech**,
pour la modernisation de la gestion foncière en République du Togo.

- Cahier des charges : [`docs/Cahier_de_charges_V2_TrustLand.docx`](docs/Cahier_de_charges_V2_TrustLand.docx)
- Canevas initial : [`docs/CANEVA_CAHIER_DE_CHARGE_finaliser.docx`](docs/CANEVA_CAHIER_DE_CHARGE_finaliser.docx)

> **Note de sécurité** : ne jamais commiter de secrets (`.env`, clés, mots de passe).
> Les secrets exposés dans l'historique Git doivent être considérés comme compromis et révoqués.
