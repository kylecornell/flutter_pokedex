# Pokédex

A Flutter Pokédex powered by [PokéAPI](https://pokeapi.co/api/v2/).
Built feature-first, with a small, beginner-friendly layered architecture.

## Features

| Feature | What it does | Route |
|---|---|---|
| Home | Entry point, links to everything | `/` |
| Pokédex | Paginated grid, search by name or number, filter by type | `/pokedex` |
| Pokémon details | Artwork, types, size, base stats, evolution chain | `/pokemon/:id` |
| Type Explorer | 18 type orbs, attack/defense chart per type | `/types`, `/types/:name` |
| Type Matchup | Attacker vs one or two defender types, full damage-taken chart | `/types/matchup` |
| Favorites | Heart a Pokémon anywhere, saved on device | `/favorites` |
| Settings | Theme (system/light/dark), animations, grid size | `/settings` |

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
    theme/                   colors + light/dark themes
  core/                      technical code, knows nothing about Pokémon
    constants/               API base URL, timeouts
    errors/                  AppException types
    network/                 ApiClient (http + error mapping)
    storage/                 SharedPreferences provider
    utils/                   text formatting
    widgets/                 ErrorView
  shared/                    Pokémon-aware code used by 2+ features
    models/                  Pokemon, PokemonType, EvolutionChain, AppSettings
    datasources/             PokeApiDataSource, local favorites/settings
    repositories/            PokemonRepository, TypeRepository
    providers/               Riverpod providers (repos, favorites, settings)
    widgets/                 PokemonCard, PokemonGrid, TypeBadge, ...
  features/                  one folder per feature
    pokedex/ pokemon_details/ type_explorer/ favorites/ settings/ home/
      presentation/screens   full pages
      presentation/widgets   pieces only this feature uses
      presentation/providers feature state (Riverpod)
      domain/                pure logic (e.g. TypeEffectivenessService)
test/
  unit/  widget/  fixtures/  helpers/
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

Example: opening the Pokédex.

```text
PokedexScreen                 shows cards, asks for the next page on scroll
  → pokedexListProvider        feature state: items, isLoading, hasMore, error
  → PokemonRepository          parses JSON into models, caches
  → PokeApiDataSource          knows the URLs
  → ApiClient                  http call, timeout, maps failures to AppException
  → PokéAPI
```

Going back up: JSON → `PokemonPage` → provider state → `PokemonGrid`.

| Step | File |
|---|---|
| Screen | `features/pokedex/presentation/screens/pokedex_screen.dart` |
| State | `features/pokedex/presentation/providers/pokedex_list_provider.dart` |
| Repository | `shared/repositories/pokemon_repository.dart` |
| Data source | `shared/datasources/pokeapi_datasource.dart` |
| HTTP | `core/network/api_client.dart` |
| Models | `shared/models/pokemon_summary.dart` |

## State management (Riverpod)

| Kind | Example | Where |
|---|---|---|
| Local widget state | scroll position, text field | `State` class in the screen |
| Feature state | Pokédex list, search query, matchup selection | `features/*/presentation/providers` |
| Shared state | favorites, settings, repositories | `shared/providers` |

Failed `FutureProvider`s do not auto-retry (`retry: (_, _) => null`) so the
UI shows the error right away with a Retry button.

## Errors and caching

- `ApiClient` turns every failure into an `AppException`:
  `NetworkException`, `NotFoundException`, `ServerException`, `ParsingException`.
- Screens show `ErrorView` with a Retry button.
- Repositories cache in memory (Pokémon, types, evolution chains, full index).
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

## Not built yet

2D/3D model viewer, trading-card view, integration tests, custom fonts and
bundled assets (`assets/` is created when the first asset is added).
