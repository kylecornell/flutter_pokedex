# Pokédex

A Flutter Pokédex powered by [PokéAPI](https://pokeapi.co/api/v2/).
Built feature-first, with a small, beginner-friendly layered architecture.

## Features

| Feature | What it does | Route |
|---|---|---|
| Home | Hero header, search with suggestions, dual-type chips, recently viewed, "Surprise me" | `/` |
| Pokédex | National Dex: sort (No./A–Z), generation chips, dual-type filter | `/pokedex` |
| Details | Collectible card (flip, tilt, foil, rarity ribbon), forms, tabs: Overview, Stats, Evolution, Moves, Abilities | `/pokemon/:id` |
| Viewer modes | Artwork, animated sprite, 3D model (optional, with fallbacks) | on the card |
| Type Explorer | 18 orbs; Attack / Defense; orbit and list views; focus a matchup | `/types`, `/types/:name` |
| Type Matchup | Attacker vs one or two defender types | `/types/matchup` |
| Catch | Throw balls at a wild Pokémon; camera background or practice field | `/catch` |
| Favorites | "My collection": search, type filter, progress bar | `/favorites` |
| Settings | Theme, animations, card effects, grid size, default viewer mode, clear cache | `/settings` |

The four tabs (Home, Pokédex, Favorites, Settings) sit in a shell with a
bottom navigation bar and a raised Pokéball **Catch** button. Every other
screen opens full screen above the tabs.

## Run

```bash
flutter pub get
flutter run            # pick a device
flutter analyze
flutter test
```

Needs internet (PokéAPI). Favorites and settings are stored with
`shared_preferences`.

## Folder structure

```text
lib/
  main.dart                  loads SharedPreferences, starts the app
  app/                       app-wide setup
    app.dart                 MaterialApp.router, theme mode
    router/app_router.dart   every route lives here
    shell/                   tab shell + bottom navigation
    theme/                   design tokens (AppPalette), fonts, ThemeData
  core/                      technical code, knows nothing about Pokémon
    constants/ errors/ network/ storage/ utils/ widgets/
  shared/                    Pokémon-aware code used by 2+ features
    domain/                  filtering (search, type, generation, sort)
    models/                  Pokemon, PokemonSpecies, PokemonType, ...
    datasources/             PokeApiDataSource, local favorites/settings
    repositories/            Pokemon, Type, Model3d
    providers/               Riverpod providers (repos, favorites, settings)
    widgets/                 PokemonCard, grid, chips, TypeOrb, TypeBadge, ...
  features/                  one folder per feature
    home/ pokedex/ pokemon_details/ type_explorer/
    catch/ favorites/ settings/
      presentation/screens   full pages
      presentation/widgets   pieces only this feature uses
      presentation/providers feature state (Riverpod)
      domain/                pure logic (card view model, type chart, catch odds)
test/
  unit/  widget/  fixtures/  helpers/   (helpers/fake_api.dart = fake PokéAPI)
```

### `core` vs `shared`

- **core**: could be copied into any app (HTTP client, error types).
- **shared**: only makes sense in *this* app, and two or more features need it
  (the `Pokemon` model, the Pokémon card).

### Rule of thumb

> A feature never imports another feature. If two features need something,
> move it to `shared/`.

This is why favorites state, the Pokémon card and the repositories live in
`shared/` even though they feel like they belong to one feature.

## Data flow

Example: the Pokédex tab.

```text
PokedexScreen                  filter chips + lazy "scroll for more"
  → dexFilterProvider           feature state: types, sort, generation
  → pokemonIndexProvider        all 1025 names, fetched once
  → typeIndexProvider           id → types, built from 18 /type calls, cached
  → filterPokemon()             pure function in shared/domain
  → SliverPokemonGrid → PokemonCard
```

Behind the providers: `PokemonRepository` / `TypeRepository` (parse + cache)
→ `PokeApiDataSource` (URLs, raw JSON) → `ApiClient` (http, timeout, typed
errors).

| Step | File |
|---|---|
| Screen | `features/pokedex/presentation/screens/pokedex_screen.dart` |
| Filter state | `features/pokedex/presentation/providers/dex_filter_provider.dart` |
| Filtering | `shared/domain/pokemon_filtering.dart` |
| Type index | `shared/providers/type_providers.dart` |
| Repository | `shared/repositories/pokemon_repository.dart` |
| Data source | `shared/datasources/pokeapi_datasource.dart` |
| HTTP | `core/network/api_client.dart` |

## State management (Riverpod)

| Kind | Example | Where |
|---|---|---|
| Local widget state | scroll position, text field | `State` class in the screen |
| Feature state | Pokédex list, search query, matchup selection | `features/*/presentation/providers` |
| Shared state | favorites, settings, repositories | `shared/providers` |

Failed `FutureProvider`s do not auto-retry (`retry: (_, _) => null`) so the
UI shows the error right away with a Retry button.

## Design system

Tokens come from the Pokédex design: `app/theme/app_colors.dart`
(`AppPalette`, light and dark, read with `context.palette`), Fredoka for
headings and Nunito for text via `google_fonts` (`app_typography.dart`).
Type colors and the readable "ink" on each live in
`shared/widgets/type_badge.dart`.

## Errors and caching

- `ApiClient` turns every failure into an `AppException`:
  `NetworkException`, `NotFoundException`, `ServerException`, `ParsingException`.
- Screens show `ErrorView` with a Retry button.
- Repositories cache in memory (Pokémon, species, types, evolution chains,
  abilities, moves, the full index).
- The type index (id → types) is also stored on the device, so later
  launches skip 18 requests. Settings > Clear resets it.
- Images use `cached_network_image` (disk + memory).
- Models fall back to safe defaults when optional fields are missing.

## Conventions

- One main job per file. Screens arrange widgets; they do not call `http`.
- Imports are relative inside `lib/`.
- Create folders only when they hold a file.
- Every new repository or provider gets a test. Widget tests override the
  repository providers with a `MockClient` (see `test/widget/`).
- Run `flutter analyze` and `flutter test` before committing.
- Do not hand-edit generated files (`*GeneratedPluginRegistrant*`,
  `generated_plugins.cmake`, `pubspec.lock`).

## How to add things

### A new screen

1. Create `features/<feature>/presentation/screens/my_screen.dart`.

   ```dart
   class MyScreen extends StatelessWidget {
     const MyScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: const Text('My screen')),
         body: const Center(child: Text('Hello')),
       );
     }
   }
   ```

2. Register it in `app/router/app_router.dart`:

   ```dart
   GoRoute(path: '/my-screen', builder: (context, state) => const MyScreen()),
   ```

3. Navigate with `context.push('/my-screen')`.

Path parameters: `path: '/pokemon/:id'` → `state.pathParameters['id']`.

### A reusable widget

- Used by one feature → `features/<feature>/presentation/widgets/`.
- Used by two or more → `shared/widgets/`.
- Not Pokémon-specific (spinner, error box) → `core/widgets/`.

Keep it dumb: take data and callbacks as constructor arguments.

### A new API call

1. **Data source** (`shared/datasources/pokeapi_datasource.dart`): add one
   method that returns raw JSON.

   ```dart
   Future<Map<String, dynamic>> fetchMove(String name) =>
       _client.getJson('move/${name.toLowerCase()}');
   ```

2. **Model** (`shared/models/move.dart`): `Move.fromJson` with fallbacks.
3. **Repository**: call the data source, parse, cache, wrap parse errors in
   `ParsingException`.
4. **Provider**: expose it to the UI.

   ```dart
   final moveProvider = FutureProvider.family<Move, String>(
     (ref, name) => ref.watch(moveRepositoryProvider).getMove(name),
     retry: (_, _) => null,
   );
   ```

5. **Test**: put a trimmed JSON response in `test/fixtures/` and test the
   repository with `MockClient`.

Never call `ApiClient` from a screen.

### A new feature

1. `features/my_feature/presentation/screens/` (+ `widgets/`, `providers/`).
2. Add `domain/` only if there is real logic (pure Dart, no Flutter).
3. Need data? Reuse a repository from `shared/`. If two features will use the
   new data, put its datasource/repository in `shared/` too.
4. Add the route in `app_router.dart` and a link from Home.
5. Add tests under `test/unit` and `test/widget`.

## Files you should not touch casually

`pubspec.lock`, `android/**` (Gradle, manifest, signing), `ios/`, `macos/`,
`linux/`, `windows/`, `web/`, `.metadata`, `analysis_options.yaml`.
Never commit keystores, `key.properties` or credentials.

## Assets, licenses and limits

- Data: [PokéAPI](https://pokeapi.co). Artwork and sprites: the PokeAPI
  sprites repository.
- 3D models come from the community "Pokémon 3D API" asset repository.
  They are fan-made and **non-commercial**, not every Pokémon has one, and
  the app always falls back to artwork.
- Animated sprites are Showdown GIFs where they exist, then the static
  sprite, then artwork.
- Unofficial fan project. Pokémon and character names are trademarks of
  Nintendo, Game Freak and Creatures.

## Android permissions

`INTERNET` (data and images), `CAMERA` (optional, Catch background) and
`usesCleartextTraffic` (the 3D viewer serves models from a local address).

## Not built yet

Integration tests (`integration_test/`), bundled assets (`assets/` is
created when the first asset is added), 3D camera reset and animation
picker (the `model_viewer_plus` API does not expose them), type-specific
particle effects in the Type Explorer.
