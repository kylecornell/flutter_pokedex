import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../shared/domain/pokemon_filtering.dart';
import '../../../../shared/models/generation.dart';
import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/type_providers.dart';
import '../../../../shared/widgets/chips.dart';
import '../../../../shared/widgets/lazy_scroll.dart';
import '../../../../shared/widgets/pokedex_header.dart';
import '../../../../shared/widgets/pokemon_grid.dart';
import '../providers/dex_filter_provider.dart';

/// The National Dex: sort, generation and (dual) type filters.
class PokedexScreen extends ConsumerStatefulWidget {
  const PokedexScreen({super.key});

  @override
  ConsumerState<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends ConsumerState<PokedexScreen> {
  late final LazyReveal _reveal;

  @override
  void initState() {
    super.initState();
    _reveal = LazyReveal(step: 30, onChanged: () => setState(() {}));
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final filter = ref.watch(dexFilterProvider);
    final notifier = ref.read(dexFilterProvider.notifier);
    final index = ref.watch(pokemonIndexProvider);
    final typeIndex = ref.watch(typeIndexProvider);

    final all = index.value ?? const <PokemonSummary>[];
    final results = filterPokemon(
      all,
      types: filter.types,
      typeIndex: typeIndex.value ?? const {},
      generationIndex: filter.generationIndex,
      sort: filter.sort,
    );
    _reveal.total = results.length;
    final shown = results.take(_reveal.visible).toList();

    final count = index.hasValue
        ? '${formatCount(results.length)} of ${formatCount(all.length)} · National Dex'
        : 'Loading…';

    return Material(
      type: MaterialType.transparency,
      child: CustomScrollView(
        controller: _reveal.controller,
        slivers: [
          SliverToBoxAdapter(
            child: PokedexHeader(
              accent: HeaderAccent.green,
              title: 'Pokédex',
              subtitle: count,
              actions: [
                SegmentedPill<PokemonSort>(
                  expand: false,
                  height: 32,
                  options: const {
                    PokemonSort.number: 'No.',
                    PokemonSort.name: 'A–Z',
                  },
                  value: filter.sort,
                  onChanged: (s) {
                    _reveal.reset();
                    notifier.setSort(s);
                  },
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 14),
            sliver: SliverToBoxAdapter(
              child: _Filters(
                filter: filter,
                onGeneration: (g) {
                  _reveal.reset();
                  notifier.setGeneration(g);
                },
                onTypes: (t) {
                  _reveal.reset();
                  notifier.setTypes(t);
                },
              ),
            ),
          ),
          if (index.hasError && !index.hasValue)
            SliverToBoxAdapter(
              child: ErrorView(
                error: index.error!,
                onRetry: () => ref.invalidate(pokemonIndexProvider),
              ),
            )
          else if (index.hasValue && results.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No Pokémon match these filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.mutedForeground),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              sliver: SliverPokemonGrid(
                items: shown,
                onTap: (s) => context.push('/pokemon/${s.id}'),
              ),
            ),
            if (results.length > shown.length)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Scroll for more',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: p.mutedForeground),
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.filter,
    required this.onGeneration,
    required this.onTypes,
  });

  final DexFilter filter;
  final ValueChanged<int> onGeneration;
  final ValueChanged<List<String>> onTypes;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipScroller(
          height: 32,
          spacing: 6,
          children: [
            PillChip(
              label: 'All gens',
              selected: filter.generationIndex < 0,
              height: 32,
              radius: 9,
              fontSize: 12,
              onTap: () => onGeneration(-1),
            ),
            for (final (i, g) in pokemonGenerations.indexed)
              PillChip(
                label: '${g.roman} · ${g.region}',
                selected: filter.generationIndex == i,
                height: 32,
                radius: 9,
                fontSize: 12,
                onTap: () => onGeneration(i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TypeChipRow(
          selected: filter.types,
          onChanged: onTypes,
          height: 32,
          fontSize: 12,
        ),
      ],
    );
  }
}
