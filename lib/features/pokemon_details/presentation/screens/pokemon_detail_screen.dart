import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../shared/models/app_settings.dart';
import '../../../../shared/models/pokemon.dart';
import '../../../../shared/models/pokemon_species.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/recent_provider.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../../../shared/widgets/chips.dart';
import '../../../../shared/widgets/favorite_button.dart';
import '../../../../shared/widgets/pokedex_header.dart';
import '../../domain/card_view_model.dart';
import '../providers/pokemon_detail_provider.dart';
import '../widgets/card_viewer.dart';
import '../widgets/tabs/abilities_tab.dart';
import '../widgets/tabs/evolution_tab.dart';
import '../widgets/tabs/moves_tab.dart';
import '../widgets/tabs/overview_tab.dart';
import '../widgets/tabs/stats_tab.dart';
import '../widgets/trading_card.dart';

enum _InfoTab {
  overview('Overview'),
  stats('Stats'),
  evolution('Evolution'),
  moves('Moves'),
  abilities('Abilities');

  const _InfoTab(this.label);

  final String label;
}

/// Details page: collectible card (flip, tilt, foil) + info tabs.
/// [pokemonId] comes from the route (`/pokemon/:id`).
class PokemonDetailScreen extends ConsumerStatefulWidget {
  const PokemonDetailScreen({super.key, required this.pokemonId});

  final String pokemonId;

  @override
  ConsumerState<PokemonDetailScreen> createState() =>
      _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends ConsumerState<PokemonDetailScreen> {
  // Local widget state: nothing here outlives the page.
  late ViewerMode _mode;
  bool _flipped = false;
  bool _full = false;
  _InfoTab _tab = _InfoTab.overview;
  int? _formId; // null = the opened Pokémon itself

  @override
  void initState() {
    super.initState();
    _mode = ref.read(settingsProvider).viewerMode;
  }

  void _retry() {
    ref.invalidate(pokemonDetailProvider(widget.pokemonId));
    final base = ref.read(pokemonDetailProvider(widget.pokemonId)).value;
    if (base != null) ref.invalidate(speciesProvider(base.speciesName));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final baseAsync = ref.watch(pokemonDetailProvider(widget.pokemonId));
    final base = baseAsync.value;

    ref.listen(pokemonDetailProvider(widget.pokemonId), (_, next) {
      final value = next.value;
      if (value != null) {
        ref.read(recentProvider.notifier).add(value.id);
      }
    });

    final speciesAsync =
        base == null ? null : ref.watch(speciesProvider(base.speciesName));
    final species = speciesAsync?.value;
    final formAsync = _formId == null
        ? null
        : ref.watch(pokemonDetailProvider('$_formId'));
    final shown = formAsync?.value ?? base;

    final failure = baseAsync.hasError
        ? baseAsync.error
        : (speciesAsync?.hasError ?? false)
            ? speciesAsync!.error
            : null;
    final ready = base != null && species != null && shown != null;

    final PokemonForm? selectedForm = _formId == null || species == null
        ? null
        : species.forms.where((f) => f.id == _formId).firstOrNull;

    final data = ready
        ? CardViewModel.build(
            pokemonId: base.id,
            pokemon: shown,
            species: species,
            form: selectedForm,
          )
        : null;

    final title = data?.name ?? 'Pokémon';
    final number = ready ? formatDexNumber(base.id) : '';

    final cardBlock = ready
        ? _CardBlock(
            data: data!,
            species: species,
            shownId: shown.id,
            baseId: base.id,
            mode: _mode,
            flipped: _flipped,
            full: _full,
            selectedFormId: _formId,
            onMode: (m) => setState(() => _mode = m),
            onFlip: () => setState(() => _flipped = !_flipped),
            onToggleFull: () => setState(() => _full = !_full),
            onForm: (form) => setState(
              () => _formId = form.isDefault ? null : form.id,
            ),
          )
        : null;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              children: [
                PokedexHeader(
                  accent: HeaderAccent.red,
                  title: title,
                  subtitle: number.isEmpty ? null : number,
                  onBack: () => context.canPop() ? context.pop() : context.go('/'),
                  actions: [
                    if (ready)
                      FavoriteButton(
                        pokemonId: base.id,
                        inactiveColor: HeaderAccent.red.ink,
                      ),
                  ],
                ),
                Expanded(
                  child: failure != null
                      ? ErrorView(error: failure, onRetry: _retry)
                      : !ready
                          ? const _LoadingSkeleton()
                          : ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    18,
                                    20,
                                    14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color.lerp(
                                          p.background,
                                          data!.color1,
                                          0.3,
                                        )!,
                                        p.background,
                                      ],
                                    ),
                                  ),
                                  child: _full
                                      ? const SizedBox(height: 413)
                                      : cardBlock,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
                                  child: _InfoSection(
                                    tab: _tab,
                                    onTab: (t) => setState(() => _tab = t),
                                    data: data,
                                    pokemon: shown,
                                    species: species,
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
          if (_full && ready)
            Positioned.fill(
              child: Container(
                color: const Color(0xE009090B),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          child: Transform.scale(scale: 1.1, child: cardBlock),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: IconButton.filled(
                          tooltip: 'Close full screen',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.12),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(44, 44),
                          ),
                          onPressed: () => setState(() => _full = false),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = (MediaQuery.sizeOf(context).width - 40).clamp(240.0, 296.0);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: width,
            height: width * 88 / 63,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.border),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card + display mode switch + form chips.
class _CardBlock extends ConsumerWidget {
  const _CardBlock({
    required this.data,
    required this.species,
    required this.shownId,
    required this.baseId,
    required this.mode,
    required this.flipped,
    required this.full,
    required this.selectedFormId,
    required this.onMode,
    required this.onFlip,
    required this.onToggleFull,
    required this.onForm,
  });

  final CardViewModel data;
  final PokemonSpecies species;
  final int shownId;
  final int baseId;
  final ViewerMode mode;
  final bool flipped;
  final bool full;
  final int? selectedFormId;
  final ValueChanged<ViewerMode> onMode;
  final VoidCallback onFlip;
  final VoidCallback onToggleFull;
  final ValueChanged<PokemonForm> onForm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final width = (MediaQuery.sizeOf(context).width - 40).clamp(240.0, 296.0);

    final hint = viewerHint(mode);

    return Column(
      children: [
        TradingCard(
          width: width,
          data: data,
          flipped: flipped,
          effects: settings.cardEffects,
          animations: settings.animationsEnabled,
          tiltEnabled: mode != ViewerMode.model3d,
          onFlip: onFlip,
          onTypeTap: (t) => context.push('/types/$t'),
          viewer: CardViewer(
            pokemonId: shownId,
            name: data.name,
            mode: mode,
            onShowArtwork: () => onMode(ViewerMode.art),
          ),
          viewerOverlay: Stack(
            children: [
              Positioned(
                top: 6,
                right: 6,
                child: Semantics(
                  button: true,
                  label: full ? 'Exit full screen' : 'Full screen',
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.88),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onToggleFull,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          full ? Icons.fullscreen_exit : Icons.fullscreen,
                          size: 18,
                          color: const Color(0xFF18181B),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (hint.isNotEmpty)
                Positioned(
                  left: 6,
                  bottom: 5,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        hint,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: width,
          child: OutlinedButton.icon(
            onPressed: onFlip,
            icon: const Icon(Icons.flip, size: 18),
            label: Text(flipped ? 'Show front' : 'Flip card'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: width,
          child: SegmentedPill<ViewerMode>(
            height: 38,
            radius: 12,
            options: {for (final m in ViewerMode.values) m: m.label},
            value: mode,
            onChanged: onMode,
          ),
        ),
        if (species.forms.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: width,
            child: ChipScroller(
              horizontalPadding: 0,
              spacing: 6,
              children: [
                for (final form in species.forms)
                  PillChip(
                    label: form.label,
                    dotColor: _kindDot(form.kind),
                    selected: form.id == (selectedFormId ?? baseId) ||
                        (form.isDefault && selectedFormId == null),
                    onTap: () => onForm(form),
                    fontSize: 12,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

Color _kindDot(FormKind kind) => switch (kind) {
      FormKind.base => const Color(0xFFA1A1AA),
      FormKind.mega => const Color(0xFFA855F7),
      FormKind.gmax => const Color(0xFFEF4444),
      FormKind.regional => const Color(0xFF22C55E),
      FormKind.other => const Color(0xFFEAB308),
    };

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.tab,
    required this.onTab,
    required this.data,
    required this.pokemon,
    required this.species,
  });

  final _InfoTab tab;
  final ValueChanged<_InfoTab> onTab;
  final CardViewModel data;
  final Pokemon pokemon;
  final PokemonSpecies species;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              for (final t in _InfoTab.values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: t == tab,
                    child: InkWell(
                      onTap: () => onTab(t),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: t == tab ? p.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: FittedBox(
                          child: Text(
                            t.label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: t == tab ? p.foreground : p.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: switch (tab) {
          _InfoTab.overview => OverviewTab(data: data),
          _InfoTab.stats => StatsTab(
              key: ValueKey(pokemon.id),
              stats: pokemon.stats,
              color: data.color1,
            ),
          _InfoTab.evolution => EvolutionTab(
              speciesName: species.name,
              currentId: pokemon.id,
              highlight: data.color1,
            ),
          _InfoTab.moves => MovesTab(
              key: ValueKey(pokemon.id),
              moves: pokemon.moves,
              versionGroupName: pokemon.versionGroupName,
            ),
          _InfoTab.abilities => AbilitiesTab(abilities: pokemon.abilities),
          },
        ),
      ],
    );
  }
}
