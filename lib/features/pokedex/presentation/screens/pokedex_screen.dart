import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/error_view.dart';
import '../providers/pokedex_list_provider.dart';
import '../providers/pokedex_search_provider.dart';
import '../widgets/pokemon_grid.dart';

class PokedexScreen extends ConsumerStatefulWidget {
  const PokedexScreen({super.key});

  @override
  ConsumerState<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends ConsumerState<PokedexScreen> {
  // Local widget state: scroll position and text field contents.
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    final nearBottom = position.pixels >= position.maxScrollExtent - 400;
    final state = ref.read(pokedexListProvider);
    // Skip while an error is showing so we don't hammer the API; the Retry
    // button reloads explicitly.
    if (nearBottom && state.error == null) {
      ref.read(pokedexListProvider.notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(pokedexSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search by name or number',
              leading: const Icon(Icons.search),
              trailing: [
                if (query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(pokedexSearchQueryProvider.notifier).set('');
                    },
                  ),
              ],
              onChanged: ref.read(pokedexSearchQueryProvider.notifier).set,
            ),
          ),
          Expanded(
            child: query.trim().isEmpty ? _buildBrowse() : _buildSearch(),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowse() {
    final state = ref.watch(pokedexListProvider);
    final notifier = ref.read(pokedexListProvider.notifier);

    if (state.items.isEmpty) {
      if (state.error != null) {
        return ErrorView(error: state.error!, onRetry: notifier.loadNextPage);
      }
      return const Center(child: CircularProgressIndicator());
    }

    Widget? footer;
    if (state.error != null) {
      footer = Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: TextButton(
            onPressed: notifier.loadNextPage,
            child: Text('${state.error!.message} Tap to retry.'),
          ),
        ),
      );
    } else if (state.hasMore) {
      footer = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return PokemonGrid(
      items: state.items,
      controller: _scrollController,
      footer: footer,
    );
  }

  Widget _buildSearch() {
    final results = ref.watch(pokedexSearchResultsProvider);
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(pokemonIndexProvider),
      ),
      data: (items) => items.isEmpty
          ? const Center(child: Text('No Pokémon found.'))
          : PokemonGrid(items: items),
    );
  }
}
