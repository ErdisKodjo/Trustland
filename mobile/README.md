# TrustLand Mobile — Flutter

Application compagnon du registre foncier numérique **TrustLand** (Togo).
**Migration Expo / React Native → Flutter** (décision équipe, 29-09-2026) :
même palette, mêmes écrans, même API — codebase native plus performante
et outil de build unique.

![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.4%2B-0175C2?logo=dart&logoColor=white)

## 🎨 Design system « Cadastre »

Identité visuelle **identique au web** (`frontend/src/index.css`) — source de
vérité unique dans `lib/core/theme/app_theme.dart` :

| Rôle | Token | Hex |
|------|-------|-----|
| Primaire | `Forest.green700` (vert cadastre) | `#1E5A31` |
| Primaire sombre | `Forest.green900` | `#12301C` |
| Fond app | `Forest.canvas` (toile os) | `#FAF9F5` |
| Bordures | `Forest.border` | `#E4E6DC` |
| Texte | `Forest.ink` / `Forest.mute` | `#101510` / `#5D675E` |
| Info | `Forest.info` (bleu logo) | `#1D5C96` |
| Alerte | `Forest.amber600` | `#B45309` |
| Danger | `Forest.danger` | `#B3261E` |

Material 3, `ColorScheme` construit à la main (pas de `fromSeed`) pour garder
la palette exacte. Composants réutilisables dans `lib/widgets/widgets.dart`
(`StatCard`, `StatusBadge`, `TerrainCard`, `EmptyState`, `InfoRow`,
`ProprietairePicker`…).

## 🔔 Notifications push (Firebase Cloud Messaging)

Le mobile utilise **FCM** (`firebase_messaging`) ; le backend enregistre les
tokens natifs via `POST /api/push-token/` et relaie les envois via l'API
Expo Push v2 (compatible FCM/APNs).

L'app **fonctionne sans push** : si Firebase n'est pas configuré,
`PushService` ignore silencieusement l'initialisation.

### Configuration (une fois, par le propriétaire du projet)

```bash
# 1. Créer un projet sur https://console.firebase.google.com
#    (Android : package com.trustland.app · iOS : bundle com.trustland.app)
# 2. Générer les fichiers de configuration Flutter :
dart pub global activate flutterfire_cli
flutterfire configure            # écrit lib/firebase_options.dart
# 3. Android : télécharger google-services.json → android/app/
#    iOS      : télécharger GoogleService-Info.plist → ios/Runner/ (Xcode)
# 4. (Envoi via Expo Push) Renseigner la clé serveur FCM du projet
#    Firebase dans les credentials du projet Expo associé au backend.
```

Comportement après configuration :

| Situation | Effet |
|---|---|
| Message premier-plan | Bandeau in-app + bouton « Voir » |
| Tap notification (arrière-plan) | Ouvre la fiche terrain si `data.terrainId` |
| Cold start depuis notification | Même navigation |
| Rotation du token FCM | Ré-enregistrement automatique |

## 📦 Prérequis

- **Flutter SDK ≥ 3.22** (`flutter doctor` sans erreur)
- Backend Django TrustLand joignable (voir config réseau ci-dessous)

## 🚀 Mise en route

Les dossiers plateformes (`android/`, `ios/`) ne sont **pas versionnés** :
ils sont générés localement, puis personnalisés avec les permissions.

```bash
cd mobile

# 1. Dépendances Dart
flutter pub get

# 2. Générer les dossiers plateformes (conserve lib/ et pubspec.yaml)
flutter create . --org com.trustland --project-name trustland_mobile \
    --platforms android,ios

# 3. Lancer (backend joignable — voir config réseau)
flutter run
```

### ⚙️ Config réseau (IP du backend)

`lib/core/config.dart` :

```dart
const String kApiBaseUrl = 'http://192.168.1.70:8000';
```

Surcharge possible au build : `flutter run --dart-define=TRUSTLAND_API=http://10.0.2.2:8000`
(`10.0.2.2` = host depuis l'émulateur Android).

### 🔐 Permissions à ajouter après `flutter create`

**Android — `android/app/src/main/AndroidManifest.xml`** (hors balise `<application>`) :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

**iOS — `ios/Runner/Info.plist`** :

```xml
<key>NSCameraUsageDescription</key>
<string>TrustLand utilise la caméra pour photographier les terrains et scanner les QR codes.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>TrustLand accède à vos photos pour documenter les terrains.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>TrustLand utilise votre position pour remplir les coordonnées GPS.</string>
<key>NSFaceIDUsageDescription</key>
<string>TrustLand utilise Face ID pour déverrouiller l'application.</string>
```

## 🗂 Architecture

```
mobile/
├── assets/                    logo (icon.png, splash-icon.png)
├── lib/
│   ├── main.dart              point d'entrée (restauration de session, FCM)
│   ├── app.dart               MaterialApp + thème + routeur d'état + lock
│   ├── services/push_service.dart  FCM : token → backend, bandeaux, navigation
│   ├── core/
│   │   ├── config.dart        IP backend, timeouts
│   │   ├── theme/app_theme.dart   ★ design system Forest (Material 3)
│   │   ├── network/api_client.dart  Dio + JWT + refresh transparent
│   │   └── storage/           tokens chiffrés + cache hors-ligne
│   ├── models/models.dart     User, Terrain, Transaction, Alerte, Stats…
│   ├── state/
│   │   ├── auth_provider.dart session + verrouillage inactivité 10 min
│   │   └── data_provider.dart terrains/stats/transactions/alertes + cache
│   ├── screens/
│   │   ├── splash/ auth (login + inscription) / shell (5 onglets) / lock
│   │   ├── home/              stats, raccourcis, alertes IA
│   │   ├── terrains/          liste + filtres, détail, création (GPS + photo)
│   │   ├── carte/             OpenStreetMap (flutter_map, zéro clé API)
│   │   ├── verifier/          contrôle de documents + scan QR
│   │   ├── forms/             transaction, litige
│   │   └── profil/            identité, sécurité, déconnexion
│   └── widgets/widgets.dart   bibliothèque de composants « Cadastre »
└── pubspec.yaml
```

## 🔌 Endpoints consommés (identiques à l'app Expo)

| Endpoint | Usage |
|----------|-------|
| `POST /api/token/` + `/api/token/refresh/` | authentification JWT |
| `POST /api/users/register/` | inscription publique (rôle propriétaire) + auto-connexion |
| `GET /api/users/me/` | profil |
| `GET /api/stats/` | tableau de bord |
| `GET /api/terrains/` (+ création) | registre des terrains |
| `GET /api/proprietaires/` | sélecteurs de formulaires |
| `POST /api/transactions/` | transferts de propriété |
| `POST /api/litiges/` | déclarations de litige |
| `POST /api/documents/verifier/` | contrôle d'authenticité |
| `GET /api/terrains/{id}/certificat/` | certificat PDF (partage) |

## 🔁 Équivalences Expo → Flutter

| Expo (avant) | Flutter (après) |
|--------------|-----------------|
| expo-router (tabs) | `NavigationBar` + `IndexedStack` |
| axios + interceptors | `dio` + `InterceptorsWrapper` (refresh 401) |
| expo-secure-store | `flutter_secure_storage` (Keystore/Keychain) |
| expo-local-authentication | `local_auth` |
| @react-native-community/netinfo | `connectivity_plus` |
| react-native-maps (clé API requise) | `flutter_map` + OpenStreetMap (**zéro clé**) |
| expo-camera (QR) | `mobile_scanner` |
| expo-location | `geolocator` |
| expo-image-picker | `image_picker` |
| expo-sharing + FileSystem | `share_plus` + `path_provider` |
| expo-notifications (Expo push) | `firebase_messaging` (FCM natif) — backend compat |

### 🗺️ Restant hors périmètre

- **Protection capture d'écran** : à ajouter par canal natif
  (`FLAG_SECURE` Android / champ `isSecureTextEntry` iOS) après `flutter create`.
