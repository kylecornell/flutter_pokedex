# Pokédex

Flutter Pokédex app built with a feature-first architecture.

## Run

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

## Structure

```text
lib/
  main.dart     entry point (ProviderScope + runApp)
  app/          MaterialApp, router, theme
  core/         app-agnostic tech: network, errors, constants
  shared/       Pokémon-aware code used by 2+ features
  features/     one folder per feature (data / domain / presentation)
```

Full guide (how to add a screen, widget, API service, feature) is written
in the final refactor step.
