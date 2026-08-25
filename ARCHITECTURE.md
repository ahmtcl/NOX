# NOX Architecture

## Decisions

### Feature-first Flutter structure

Features own their user journeys and can later split into `presentation`, `application`, `domain` and `data` folders without cross-feature coupling.

### Riverpod state management

Riverpod is selected for compile-time-safe dependency injection, test overrides and predictable lifecycle management. It is added now; each feature should introduce providers only when its state exists.

### GoRouter navigation

GoRouter centralizes route policy and provides a clean path for authentication, incomplete onboarding, deep links and guarded routes.

### Firebase boundaries

Firebase SDK calls stay behind repositories/services. Authentication identity is separate from `public_profiles` and `private_profiles`. Client code must never read another user’s private data.

## Planned collections

`users`, `public_profiles`, `private_profiles`, `preferences`, `interests`, `personality_answers`, `matches`, `blind_dates`, `conversations`, `messages`, `reports`, `blocks`, `verifications`, `notifications`, `subscriptions`, `purchases`, `boosts`, `moderation_events`, `safety_events`.

Access rules and server ownership must be specified per collection before implementation. Matching, moderation, account deletion and premium entitlement changes should run through Cloud Functions.

## Security and privacy

The initial rules are deny-by-default. Exact location, phone, email and other sensitive fields remain private. Age verification, App Check, rate limiting, moderation, audit events and delete-account cleanup are release gates, not UI-only features.

## Localization and design

TR and EN are supported through `AppLocalizations`; visible copy must stay outside widgets as the catalog grows. `NoxTheme` is the single source for brand colors, Material 3 color roles and component defaults. Reduced-motion and semantic-label coverage must be added as screens are implemented.
