import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/pokemon_filtering.dart';

/// Sort, generation and type filters of the Pokédex tab.
class DexFilter {
  const DexFilter({
    this.types = const [],
    this.sort = PokemonSort.number,
    this.generationIndex = -1,
  });

  /// Up to two types (dual-type filter).
  final List<String> types;
  final PokemonSort sort;

  /// Index into `pokemonGenerations`, or -1 for all generations.
  final int generationIndex;

  DexFilter copyWith({
    List<String>? types,
    PokemonSort? sort,
    int? generationIndex,
  }) {
    return DexFilter(
      types: types ?? this.types,
      sort: sort ?? this.sort,
      generationIndex: generationIndex ?? this.generationIndex,
    );
  }
}

class DexFilterNotifier extends Notifier<DexFilter> {
  @override
  DexFilter build() => const DexFilter();

  void setTypes(List<String> types) => state = state.copyWith(types: types);

  void setSort(PokemonSort sort) => state = state.copyWith(sort: sort);

  void setGeneration(int index) =>
      state = state.copyWith(generationIndex: index);
}

final dexFilterProvider =
    NotifierProvider<DexFilterNotifier, DexFilter>(DexFilterNotifier.new);
