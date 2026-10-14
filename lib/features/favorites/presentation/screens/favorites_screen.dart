import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../shared/domain/pokemon_filtering.dart';
import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/models/pokemon_types.dart';
import '../../../../shared/providers/favorites_provider.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/type_providers.dart';
import '../../../../shared/widgets/chips.dart';
import '../../../../shared/widgets/pokedex_header.dart';
import '../../../../shared/widgets/pokemon_grid.dart';

/// Saved Pokémon ("My collection"). Only ids are stored; names come from the
/// cached Pokédex index.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  // Local widget state: this search and chip never leave the screen.
  final _searchController = TextEditingController();
  String _query = '';
  String? _type;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ids = ref.watch(favoritesProvider);
    final index = ref.watch(pokemonIndexProvider);
    final typeIndex = ref.watch(typeIndexProvider).value ?? const {};

    final byId = {for (final s in index.value ?? const <PokemonSummary>[]) s.id: s};
    final saved = [for (final id in ids) ?byId[id]];
    final total = index.value?.length ?? 1025;

    final typesPresent = [
      for (final t in allPokemonTypes)
        if (saved.any((s) => (typeIndex[s.id] ?? const []).contains(t))) t,
    ];
    final visible = saved.where((s) {
      if (!matchesQuery(s, _query)) return false;
      if (_type != null && !(typeIndex[s.id] ?? const []).contains(_type)) {
        return false;
      }
      return true;
    }).toList();

    return Material(
      type: MaterialType.transparency,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PokedexHeader(
              accent: HeaderAccent.yellow,
              title: 'My collection',
              subtitle: '${saved.length} of ${formatCount(total)} collected',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            sliver: SliverList.list(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: p.muted,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: (saved.length / total).clamp(0.0, 1.0),
                      child: Container(color: p.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (index.hasError && !index.hasValue && ids.isNotEmpty)
            SliverToBoxAdapter(
              child: ErrorView(
                error: index.error!,
                onRetry: () => ref.invalidate(pokemonIndexProvider),
              ),
            )
          else if (ids.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(child: _EmptyState(onBrowse: () {
                context.go('/pokedex');
              })),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search your collection...',
                    prefixIcon: Icon(Icons.search, color: p.mutedForeground),
                    filled: true,
                    fillColor: p.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: p.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: p.border),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 12),
              sliver: SliverToBoxAdapter(
                child: TypeChipRow(
                  selected: [?_type],
                  types: typesPresent,
                  max: 1,
                  height: 32,
                  fontSize: 12,
                  onChanged: (types) => setState(
                    () => _type = types.isEmpty ? null : types.last,
                  ),
                ),
              ),
            ),
            if (visible.isEmpty && saved.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No saved Pokémon match your filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.mutedForeground),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                sliver: SliverPokemonGrid(
                  items: visible,
                  onTap: (s) => context.push('/pokemon/${s.id}'),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.favorite_border, color: p.accentForeground, size: 26),
          ),
          const SizedBox(height: 12),
          const Text(
            'No favorites yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              'Tap the heart on any Pokémon card to add it to your collection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.mutedForeground),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onBrowse, child: const Text('Browse Pokémon')),
        ],
      ),
    );
  }
}
