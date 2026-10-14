import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../shared/domain/pokemon_filtering.dart';
import '../../../../shared/models/pokemon_summary.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/recent_provider.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../../../shared/providers/type_providers.dart';
import '../../../../shared/widgets/chips.dart';
import '../../../../shared/widgets/lazy_scroll.dart';
import '../../../../shared/widgets/pokedex_header.dart';
import '../../../../shared/widgets/pokemon_grid.dart';
import '../../../../shared/widgets/type_orb.dart';
import '../providers/home_filter_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Local widget state: text field, focus, debounce and "load more".
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  late final LazyReveal _reveal;

  @override
  void initState() {
    super.initState();
    _reveal = LazyReveal(step: 20, onChanged: () => setState(() {}));
    _searchFocus.addListener(() => setState(() {}));
    _searchController.text = ref.read(homeFilterProvider).query;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _reveal.reset();
      ref.read(homeFilterProvider.notifier).setQuery(value);
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchController.clear();
    _reveal.reset();
    ref.read(homeFilterProvider.notifier).setQuery('');
    setState(() {});
  }

  void _open(int id) => context.push('/pokemon/$id');

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final filter = ref.watch(homeFilterProvider);
    final index = ref.watch(pokemonIndexProvider);
    final typeIndex = ref.watch(typeIndexProvider);
    final recent = ref.watch(recentProvider);

    final all = index.value ?? const <PokemonSummary>[];
    final results = filterPokemon(
      all,
      query: filter.query,
      types: filter.types,
      typeIndex: typeIndex.value ?? const {},
    );
    _reveal.total = results.length;

    final byId = {for (final s in all) s.id: s};
    final recentItems = [for (final id in recent) ?byId[id]];

    final title = filter.query.isNotEmpty
        ? 'Results for “${filter.query}”'
        : filter.types.isNotEmpty
            ? '${filter.types.map(formatPokemonName).join(' + ')} Pokémon'
            : 'All Pokémon';
    final count = !index.hasValue
        ? 'Loading Pokémon…'
        : (filter.types.isNotEmpty && typeIndex.isLoading)
            ? 'Loading type index…'
            : '${formatCount(results.length)} Pokémon';

    final showSuggestions = _searchFocus.hasFocus &&
        _searchController.text.trim().isNotEmpty &&
        filter.query.isNotEmpty &&
        results.isNotEmpty;

    return Material(
        type: MaterialType.transparency,
        child: CustomScrollView(
        controller: _reveal.controller,
        slivers: [
          const SliverToBoxAdapter(child: _HeroHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            sliver: SliverList.list(
              children: [
                _SearchField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onQueryChanged,
                  onClear: _clearQuery,
                ),
                if (showSuggestions) ...[
                  const SizedBox(height: 6),
                  _Suggestions(
                    items: results.take(5).toList(),
                    onTap: (s) {
                      _searchFocus.unfocus();
                      _open(s.id);
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: TypeChipRow(
              selected: filter.types,
              onChanged: (types) {
                _reveal.reset();
                ref.read(homeFilterProvider.notifier).setTypes(types);
              },
            ),
          ),
          if (filter.query.isEmpty && recentItems.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(top: 16),
              sliver: SliverToBoxAdapter(
                child: _RecentRow(items: recentItems, onTap: (s) => _open(s.id)),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            sliver: SliverToBoxAdapter(
              child: _TypeExplorerBanner(onTap: () => context.push('/types')),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(
                            18,
                            color: p.foreground,
                          ),
                        ),
                        Text(
                          count,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: all.isEmpty
                        ? null
                        : () => _open(
                              all[(DateTime.now().microsecondsSinceEpoch) %
                                      all.length]
                                  .id,
                            ),
                    icon: const Icon(Icons.shuffle, size: 16),
                    label: const Text('Surprise me'),
                  ),
                ],
              ),
            ),
          ),
          ..._content(index, results),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  List<Widget> _content(
    AsyncValue<List<PokemonSummary>> index,
    List<PokemonSummary> results,
  ) {
    final p = context.palette;
    if (index.isLoading && !index.hasValue) {
      return const [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          sliver: _SkeletonGrid(),
        ),
      ];
    }
    if (index.hasError && !index.hasValue) {
      return [
        SliverToBoxAdapter(
          child: ErrorView(
            error: index.error!,
            onRetry: () => ref.invalidate(pokemonIndexProvider),
          ),
        ),
      ];
    }
    if (results.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No Pokémon match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.mutedForeground),
            ),
          ),
        ),
      ];
    }
    final shown = results.take(_reveal.visible).toList();
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverPokemonGrid(items: shown, onTap: (s) => _open(s.id)),
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
    ];
  }
}

class _HeroHeader extends ConsumerWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PokedexHeader(
      large: true,
      accent: HeaderAccent.red,
      title: 'Pokédex',
      subtitle: 'Discover the world of Pokémon',
      actions: [
        HeaderIconButton(
          accent: HeaderAccent.red,
          tooltip: 'Toggle theme',
          icon: isDark ? Icons.light_mode : Icons.dark_mode,
          onPressed: () => ref.read(settingsProvider.notifier).setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Search Pokémon by name or number...',
        prefixIcon: Icon(Icons.search, color: p.mutedForeground),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClear,
              ),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.items, required this.onTap});

  final List<PokemonSummary> items;
  final ValueChanged<PokemonSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          for (final s in items)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onTap(s),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Image.network(
                      s.spriteUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(width: 36),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        formatPokemonName(s.name),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatDexNumber(s.id),
                      style: monoStyle(11, color: p.mutedForeground),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.items, required this.onTap});

  final List<PokemonSummary> items;
  final ValueChanged<PokemonSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
          child: Text(
            'RECENTLY VIEWED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.55,
              color: p.mutedForeground,
            ),
          ),
        ),
        ChipScroller(
          height: 44,
          children: [
            for (final s in items)
              Material(
                color: p.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: p.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(s),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 12, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          s.spriteUrl,
                          width: 38,
                          height: 38,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(width: 38),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formatPokemonName(s.name),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TypeExplorerBanner extends StatelessWidget {
  const _TypeExplorerBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 34 + 26 * 2,
                height: 34,
                child: Stack(
                  children: [
                    for (final (i, t) in ['fire', 'water', 'grass'].indexed)
                      Positioned(
                        left: i * 26.0,
                        child: TypeOrb(type: t, size: 34, iconSize: 16),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type explorer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Strengths and weaknesses for all 18 types',
                      style: TextStyle(fontSize: 12, color: p.mutedForeground),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.mutedForeground),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 158,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
      ),
    );
  }
}
