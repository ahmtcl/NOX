# NOX

NOX is a Flutter foundation for a safety-first, talk-first dating experience: **Talk first. Connect. Then reveal.**

## Current scope

This first milestone establishes the production-oriented foundation only. Large product areas such as Blind Date, chat, premium and moderation workflows are intentionally not implemented yet.

## Run locally

1. Install Flutter and run `flutter pub get`.
2. Configure a Firebase project with `flutterfire configure` (do not commit credentials).
3. Run `flutter analyze`, `flutter test`, then `flutter run`.

Until FlutterFire is configured, the app can be developed without a Firebase project; Firebase initialization is handled as an optional bootstrap.

## Architecture

- `lib/features/`: feature-first modules with isolated presentation/domain/data code as they grow.
- `lib/core/`: theme, localization, routing, errors and Firebase abstractions shared by features.
- Public and private user data use separate Firestore collections.
- Sensitive workflows (matching, moderation, deletion and entitlements) are designed to become Cloud Function/server-authoritative operations.

## Security baseline

`firestore.rules` and `storage.rules` deny access by default. A signed-in user can read public profiles and can only access their own private documents or storage paths. Reports are write-only from clients. Rules must be extended with emulator tests before production deployment.
