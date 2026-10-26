# Qasida Cayniya

Application Flutter Android de lecture de la Qasida Cayniya.

## Fonctionnalités

- lecture du PDF hors connexion ;
- reprise automatique à la dernière page ;
- favoris par page ;
- écran d'accueil simple ;
- lecture audio Cheikh Bache — Partie 1 et Partie 2 ;
- lecture des deux MP3 intégrés à l’application ;
- fonctionnement du document PDF sans connexion Internet.

## Développement

```bash
flutter pub get
flutter run
```

## APK Android

```bash
flutter build apk --release
```

L'APK est généré dans :

```text
build/app/outputs/flutter-apk/app-release.apk
```

Le workflow GitHub Actions `.github/workflows/android.yml` construit également automatiquement l'APK à chaque push sur `main`.

## Audio

Les fichiers audio suivants sont embarqués directement dans l’APK :

- `cayniya cheikh bache parti 1.mp3` ;
- `cayniya cheikh bache parti 2.mp3`.

Ouvrez **Écouter Cheikh Bache** pour écouter chaque partie. Après installation, la lecture audio fonctionne hors connexion.
