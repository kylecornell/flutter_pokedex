import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/error_view.dart';
import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/widgets/pokemon_grid.dart';

/// Saved Pokémon. Only ids are stored; names come from the cached index.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: ids.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No favorites yet.\nTap the heart on a Pokémon to save it.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ref.watch(pokemonIndexProvider).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(pokemonIndexProvider),
                ),
                data: (index) {
                  final byId = {for (final p in index) p.id: p};
                  final items = <PokemonSummary>[
                    for (final id in ids) ?byId[id],
                  ];
                  return PokemonGrid(
                    items: items,
                    onTap: (p) => context.push('/pokemon/${p.id}'),
                  );
                },
              ),
    );
  }
}
