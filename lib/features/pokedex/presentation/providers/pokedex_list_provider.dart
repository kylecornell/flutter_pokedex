import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/providers/pokemon_providers.dart';

class PokedexListState {
  const PokedexListState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<PokemonSummary> items;
  final bool isLoading;
  final bool hasMore;

  /// Set when the last page request failed. Items already loaded are kept.
  final AppException? error;
}

/// Feature state for the paginated Pokédex grid.
class PokedexListNotifier extends Notifier<PokedexListState> {
  @override
  PokedexListState build() {
    Future.microtask(loadNextPage);
    return const PokedexListState();
  }

  /// Loads the next page. Also used as "retry" after an error.
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    final items = state.items;
    state = PokedexListState(items: items, isLoading: true);

    try {
      final page = await ref.read(pokemonRepositoryProvider).getPage(
            limit: ApiConstants.defaultPageSize,
            offset: items.length,
          );
      if (!ref.mounted) return;
      state = PokedexListState(
        items: [...items, ...page.items],
        hasMore: page.hasNext,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      state = PokedexListState(items: items, error: e);
    }
  }
}

final pokedexListProvider =
    NotifierProvider<PokedexListNotifier, PokedexListState>(
  PokedexListNotifier.new,
);
