# Qasida Cayniya

Application Flutter Android de lecture de la Qasida Cayniya.

## Fonctionnalités

- lecture du PDF hors connexion ;
- reprise automatique à la dernière page ;
- favoris par page ;
- écran d'accueil simple ;
- lecture audio Cheikh Bache — Partie 1 et Partie 2 ;
- association des MP3 présents sur le téléphone ;
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

Les fichiers MP3 ne sont pas encore stockés comme assets autonomes dans le dépôt. Dans l'application, ouvrez **Écouter Cheikh Bache**, puis associez un MP3 à **Partie 1** et un autre à **Partie 2** depuis le téléphone.

Quand les deux MP3 seront ajoutés au dépôt, l'application pourra être adaptée pour les embarquer directement dans l'APK.
