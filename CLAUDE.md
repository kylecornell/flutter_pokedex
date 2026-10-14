# CLAUDE.md — Flutter Pokédex

## Project mission

Build and maintain a polished, educational Flutter Pokédex for Android. Users can discover Pokémon, search and filter the Pokédex, inspect Pokémon data, explore trading-card-inspired detail views, save favorites, and learn type matchups through interactive orbs. Optional animated sprites and interactive 3D models should enhance the experience when compatible, legally usable assets exist.

This is an existing Flutter application, not a greenfield project. Inspect the repository before assuming a feature, dependency, folder, or integration already exists. Preserve working behavior.

## Working agreement

1. **Inspect first.** Read `pubspec.yaml`, `lib/main.dart`, existing routing, themes, models, services, feature directories, and tests before suggesting changes.
2. **Do not invent project state.** Distinguish implemented, partially implemented, and proposed features. Do not claim code or tests were run unless actually executed.
3. **Plan significant changes.** Before large refactors, new dependencies, navigation changes, or platform configuration edits, present a short plan with affected files and request approval.
4. **Implement incrementally.** Prefer small, reviewable changes. Keep the app runnable after each step.
5. **Explain for a learner.** Summarize why files were created or edited, how data flows, and how to verify the result. Use concise, practical explanations.
6. **Avoid unrelated edits.** Do not rewrite functioning features, rename public interfaces, or reformat unrelated files without a clear reason.
7. **Protect local work.** Never discard user changes, run destructive Git commands, or delete directories without explicit approval.

## Technology and environment

- Flutter and Dart; Android phone is the primary test target.
- Use the Flutter and Dart SDK versions already configured by this repository.
- Prefer stable, actively maintained packages; check existing dependencies before adding new ones.
- Reuse the existing state-management and navigation solutions unless a documented problem justifies migration.
- Primary Pokémon information source: PokéAPI.
- Do not assume PokéAPI supplies downloadable 3D models.

## Feature map

Treat this as the product scope, not proof every feature has been implemented.

### Home and Pokédex

- Browse a paginated or lazily loaded Pokémon list.
- Search by Pokémon name and National Pokédex number.
- Filter by Pokémon type, including dual types; optionally filter by generation and sort.
- Show Pokémon artwork, name, number, and type badges in responsive cards.
- Handle loading, empty results, offline/network errors, and missing artwork.

### Pokémon details and collectible cards

- Present Pokémon name, number, species, types, height, weight, abilities, flavor text, stats, evolution chain, and game/version-specific moves when available.
- Use a premium, Pokémon-card-inspired UI with type-themed styling.
- Provide artwork as the reliable baseline viewer; support animated 2D sprites when available.
- Treat interactive 3D as optional and asset-dependent; show a clear fallback if unavailable.
- Keep card tilt, flip, foil effects, and transitions subtle, performant, and optional for reduced motion.

### Type Explorer

- Display all 18 types as recognizable, accessible, colored circular orbs.
- Provide Attack and Defense views; do not confuse offensive advantages with defensive weaknesses.
- Support an interactive type matchup calculator and dual-type defensive calculations.
- Use a version-consistent modern type chart, with clear multipliers and immunities.
- Connect Pokémon type badges in details to the Type Explorer where routing permits.

### Favorites and settings

- Save and remove favorites with persistent local storage.
- Support theme and animation preferences if present or requested.
- Preserve user preferences across app launches.

## Architecture guidelines

Favor feature-first organization with practical separation of presentation, domain logic, and data access. The following is a suggested direction, not an instruction to create empty folders or migrate existing files immediately:

```text
lib/
  main.dart                  # Small application entry point
  app/                       # App widget, theme, routing
  core/                      # Generic networking, errors, utilities, reusable primitives
  features/
    home/
    pokedex/
    pokemon_details/
    type_explorer/
    favorites/
    settings/
  shared/                    # Cross-feature Pokémon models, repositories, UI components
assets/
  images/
  icons/pokemon_types/
  animations/
  models_3d/
test/
integration_test/
```

- A **screen** composes UI; it should not own large API implementations or type-chart calculations.
- A **widget** renders a focused, reusable UI element.
- A **controller/provider/notifier** manages asynchronous or feature UI state using the project's established pattern.
- A **repository** offers data operations and coordinates cache/network access.
- A **data source/service** performs HTTP or local persistence operations.
- A **model** represents typed data and parsing rules.
- Put shared Pokémon entities in one canonical place. Avoid duplicate `Pokemon` or `PokemonType` definitions across features.
- Keep `main.dart` minimal; do not turn it into a catch-all file.
- Avoid excessive abstraction, premature generic frameworks, and one-line files that add no clarity.

## Data flow

Typical flow:

```text
User interaction
  -> Screen/widget
  -> Existing state manager
  -> Repository
  -> API or local data source
  -> Typed models
  -> Updated state
  -> Rendered UI
```

Use typed models, null-safe Dart, explicit error states, and consistent asynchronous patterns. Keep network access out of `build()` methods. Use pagination, request deduplication/caching where justified, and image placeholders.

## PokéAPI rules

- API base: `https://pokeapi.co/api/v2/`.
- Relevant resources include `pokemon`, `pokemon-species`, `type`, `evolution-chain`, `ability`, and `move`.
- Be careful with version-specific move learnsets and Pokédex descriptions.
- Do not fabricate data for missing API fields.
- Prefer caching stable Pokémon metadata while providing sensible refresh/error behavior.
- Avoid firing one request per item during every rebuild.
- Ensure a failed request does not crash the entire screen.

## Type effectiveness — correctness is critical

For an attacking type A against defending type D, obtain the offensive multiplier from the modern type chart:

- `0` = immune / no effect
- `0.5` = not very effective
- `1` = neutral
- `2` = super effective

For a dual-type defender, multiply both individual defensive multipliers:

```text
damageMultiplier = multiplier(attack, defenderType1) * multiplier(attack, defenderType2)
```

Examples under standard modern rules:

- Fire -> Grass = 2x.
- Rock -> Fire/Flying = 4x.
- Grass -> Fire/Flying = 0.25x.
- Ground -> Fire/Flying = 0x because Flying is immune.

Do not sum multipliers. Do not infer weaknesses by merely reversing the attacking chart. Keep Attack and Defense labeling explicit. The baseline calculator excludes abilities, items, weather, terrain, and move-specific exceptions unless specifically requested. Test all 18 types and representative dual-type cases.

## UI and accessibility

- Match the app's established design system and typography.
- Type orbs should use consistent icons and colors, but never rely on color alone: include readable labels and effectiveness text.
- Prefer responsive layouts, safe areas, minimum comfortable touch targets, readable contrast, and screen-reader semantics.
- Avoid overflowing orb layouts on small devices; offer a grid/list fallback to complex orbital visualizations.
- Make loading, error, empty, and unavailable-model states deliberate UI states.
- Respect reduced-motion preferences; minimize expensive rebuilds and effects.
- Use `const` constructors where appropriate, stable keys for changing collections, and widget extraction for clarity.

## 2D/3D asset policy

- Artwork and sprites may be loaded from supported Pokémon image sources with fallback states.
- Animated sprites should be optional when assets exist.
- 3D models require a separate legitimate source or bundled assets and a compatible renderer; do not invent URLs or promise universal coverage.
- Verify licenses and attribution requirements for icons, images, models, and animations. Do not add unlicensed proprietary assets to the repository.
- Keep the app usable without 3D assets or a network connection to a 3D provider.

## Files and configuration to protect

Do not casually delete or regenerate:

- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.gitignore`.
- Android Gradle files, manifest, signing configuration, or platform runner files.
- Existing asset files, user-created screens, data, and tests.
- Generated files such as `.dart_tool/`, `build/`, and plugin registrants: do not hand-edit them as application source.

Only modify platform configuration when necessary for an approved feature, and explain the impact. Never commit secrets, keystores, tokens, or local machine paths.

## Testing and verification

For changes where the environment permits, run:

```bash
flutter pub get
flutter analyze
flutter test
```

For UI changes, also verify on the connected Android device using the project's normal run command (typically `flutter run`). Add or update tests when behavior changes:

- **Unit tests:** type chart, dual-type multiplication, parsers, repositories.
- **Widget tests:** search, filters, empty/error states, type orb selection, favorite toggles.
- **Integration tests:** browsing -> details -> type explorer -> back navigation.

Do not claim device testing if no device is connected. Report command results and any tests that could not be performed.

## Refactoring workflow

For a structural change:

1. Inventory current files and dependencies.
2. Explain current vs. proposed structure with an existing-to-target file map.
3. Flag risky imports, routes, generated files, and state changes.
4. Request approval for major restructuring.
5. Move/refactor one feature at a time and update imports.
6. Run formatter, analyzer, and tests.
7. Summarize files changed, functionality preserved, remaining issues, and next step.

## Communication and response format

For coding tasks, respond with:

1. **Understanding:** the goal and relevant existing implementation.
2. **Plan:** smallest useful change and affected files; seek approval for major changes.
3. **Implementation:** focused edits, not unrelated rewrites.
4. **Verification:** actual commands/tests and outcomes.
5. **Explanation:** what changed, why, and what the developer should learn.

If the request is ambiguous, ask one targeted question. If there is a simpler, more maintainable option, explain the tradeoff. Favor working, understandable code over visual complexity.

## Current priority

Maintain a stable, understandable Flutter Pokédex while improving feature organization and building accurate, interactive Pokémon type exploration. On first use in this repository, perform a read-only architecture audit before making structural edits.

## Git commits and authorship (mandatory)

- Never add a co-author to any commit. Do not include `Co-authored-by:` trailers or any other co-author attribution in commit messages.
- Do not add `Generated-by:`, `Assisted-by:`, Claude attribution, or AI attribution trailers to commits.
- Use the repository's existing Git author configuration; do not change `user.name` or `user.email` to Claude or another person.
- Write concise, descriptive commit messages focused on the actual code changes.
- Do not create, amend, squash, or push commits unless explicitly requested by the user.
- If asked to commit, check the final commit message and ensure no co-author or AI attribution trailers are included. Do not rewrite historical commits unless explicitly requested.

---

## Repository specifics (current state)

The sections above are the product and process rules. This section records what this repository actually uses today, so it can be trusted without re-auditing.

### Stack

- State management: **Riverpod 3** (`flutter_riverpod`). Navigation: **go_router**, all routes in `lib/app/router/app_router.dart`.
- HTTP: `http`. Images: `cached_network_image`. Local storage: `shared_preferences`, injected from `main()` via `sharedPreferencesProvider`.
- Failed `FutureProvider`s set `retry: (_, _) => null` so errors show immediately with a manual Retry button.

### Implemented features and routes

| Route | Screen | Notes |
|---|---|---|
| `/` | Home | Links to everything, settings icon |
| `/pokedex` | Pokédex | Server pagination, name/number search over cached index, type chips |
| `/pokemon/:id` | Details | Artwork, types, size, stats, evolution chain, favorite heart |
| `/types` | Type Explorer | 18 orbs |
| `/types/:name` | Type detail | Attack and defense charts |
| `/types/matchup` | Type Matchup | Attacker vs 1–2 defender types. Declared before `/types/:name` on purpose |
| `/favorites` | Favorites | Ids stored, names from cached index |
| `/settings` | Settings | Theme mode, animations, grid density |

Not built yet: animated sprites, 3D viewer, trading-card view, flavor text, abilities, moves, generation filter, `assets/`, `integration_test/`, custom typography.

### Layering rule used here

- `core/`: app-agnostic technical code (HTTP client, error types, text helpers, `ErrorView`, prefs provider).
- `shared/`: Pokémon-aware code used by two or more features (models, datasources, repositories, providers, `PokemonCard`, `PokemonGrid`, `TypeBadge`, favorites and settings state).
- `features/<name>/`: screens, feature widgets, feature providers, optional `domain/` for pure logic (`TypeEffectivenessService`).
- **A feature never imports another feature.** If two features need something, move it to `shared/`. This is why favorites state and the Pokémon repositories are under `shared/`, not `features/favorites/data/`.
- Screens never call `ApiClient` or `http` directly. New API call path: datasource method (raw JSON) -> model `fromJson` with fallbacks -> repository (parse, cache, wrap errors in `ParsingException`) -> provider -> screen.
- Errors are `AppException` subtypes (`NetworkException`, `NotFoundException`, `ServerException`, `ParsingException`).

### Running commands from WSL

The Flutter SDK is the Windows install at `C:\src\flutter`; calling `flutter` from the WSL shell fails (CRLF in SDK scripts). Use:

```bash
cmd.exe /c "C:\src\flutter\bin\flutter.bat analyze"
cmd.exe /c "C:\src\flutter\bin\flutter.bat test"
cmd.exe /c "C:\src\flutter\bin\flutter.bat run -d <device-id>"
```

Android device used for testing: Xiaomi `M2102J20SG` (MIUI). It rejects `adb shell input` taps unless "USB debugging (Security settings)" is enabled, so UI flows must be tapped by hand.

### Testing conventions

- Fixtures: trimmed PokéAPI JSON in `test/fixtures/`.
- Repository and widget tests use `http` `MockClient` through `ApiClient(client: ...)`.
- Widget tests must override **every** repository provider a screen touches (`pokemonRepositoryProvider`, `typeRepositoryProvider`, prefs via `test/helpers/prefs.dart`). Un-overridden providers hit real HTTP, which returns 400 in the test environment.
- Last verified state: `flutter analyze` clean, 74 tests passing, debug APK installs on the test phone.

### Known issues and open decisions

- Application id is still the template `com.example.pokedex_app`; rename before any release.
- The Pokémon index includes alternate forms (ids >= 10000); the type filter drops them, search does not.
- Work lives on branch `refactor/architecture`; not merged to `main`.
- Early commits on that branch carry `Co-Authored-By` trailers added before this file existed. Per the rule above they are left as-is unless the user asks for a history rewrite.
