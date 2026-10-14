import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../shared/models/pokemon_type.dart';
import '../../../../shared/models/pokemon_types.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../../../shared/providers/type_providers.dart';
import '../../../../shared/widgets/chips.dart';
import '../../../../shared/widgets/pokedex_header.dart';
import '../../../../shared/widgets/type_badge.dart';
import '../../../../shared/widgets/type_orb.dart';
import '../../domain/type_effectiveness_service.dart';
import '../../domain/type_explorer_logic.dart';
import '../widgets/matchup_groups.dart';
import '../widgets/orbit_view.dart';

enum _View { orbit, list }

/// All 18 types. Pick one to see what it hits hard and what hits it hard,
/// as an orbit diagram or a grouped list. [initialType] opens it selected
/// (used by the type badges on the details card).
class TypeExplorerScreen extends ConsumerStatefulWidget {
  const TypeExplorerScreen({super.key, this.initialType});

  final String? initialType;

  @override
  ConsumerState<TypeExplorerScreen> createState() => _TypeExplorerScreenState();
}

class _TypeExplorerScreenState extends ConsumerState<TypeExplorerScreen> {
  // Local widget state: selection, mode and view reset every visit.
  String? _selected;
  MatchupMode _mode = MatchupMode.attack;
  _View _view = _View.orbit;
  String? _focus;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialType;
    _selected = initial != null && allPokemonTypes.contains(initial)
        ? initial
        : null;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(String? type) {
    setState(() {
      _selected = type;
      _focus = null;
    });
    if (type != null && _scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Multiplier of each type relative to the selected one, for [mode].
  Map<String, double> _chart(PokemonType data) =>
      _mode == MatchupMode.attack
          ? TypeEffectivenessService.attackChart(data)
          : TypeEffectivenessService.defenseChart([data]);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = _selected;
    final animations =
        ref.watch(settingsProvider.select((s) => s.animationsEnabled));
    final relations =
        selected == null ? null : ref.watch(pokemonTypeProvider(selected));
    final chart = relations?.value == null ? null : _chart(relations!.value!);

    return Scaffold(
      body: Column(
          children: [
            PokedexHeader(
              accent: HeaderAccent.blue,
              title: 'Type explorer',
              subtitle: '18 types · tap one to explore',
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: ListView(
                controller: _scroll,
                padding: EdgeInsets.zero,
                children: [
                  if (selected != null)
                    _SelectedHeader(
                      type: selected,
                      mode: _mode,
                      view: _view,
                      animations: animations,
                      relations: relations!,
                      chart: chart,
                      focus: _focus,
                      onMode: (m) => setState(() {
                        _mode = m;
                        _focus = null;
                      }),
                      onView: (v) => setState(() => _view = v),
                      onFocus: (t) => setState(() => _focus = t),
                      onSelect: _select,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selected == null
                                    ? 'ALL 18 TYPES · TAP TO EXPLORE'
                                    : '${formatPokemonName(selected).toUpperCase()} '
                                        '${_mode == MatchupMode.attack ? 'ATTACKING' : 'DEFENDING'}'
                                        ' · TAP A TYPE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.55,
                                  color: p.mutedForeground,
                                ),
                              ),
                            ),
                            if (selected != null)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                                onPressed: () => _select(null),
                                child: const Text('Clear'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _TypeGrid(
                          selected: selected,
                          chart: chart,
                          mode: _mode,
                          onTap: (t) => _select(t == selected ? null : t),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/types/matchup'),
                          icon: const Icon(Icons.compare_arrows),
                          label: const Text('Matchup calculator'),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Standard type chart (Gen 6 and later). Abilities, '
                          "held items and weather aren't included.",
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            color: p.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
      ),
    );
  }
}

class _SelectedHeader extends StatelessWidget {
  const _SelectedHeader({
    required this.type,
    required this.mode,
    required this.view,
    required this.animations,
    required this.relations,
    required this.chart,
    required this.focus,
    required this.onMode,
    required this.onView,
    required this.onFocus,
    required this.onSelect,
  });

  final String type;
  final MatchupMode mode;
  final _View view;
  final bool animations;
  final AsyncValue<PokemonType> relations;
  final Map<String, double>? chart;
  final String? focus;
  final ValueChanged<MatchupMode> onMode;
  final ValueChanged<_View> onView;
  final ValueChanged<String?> onFocus;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = typeColor(type);
    final attack = mode == MatchupMode.attack;
    final chart = this.chart;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(p.background, color, 0.22)!, p.background],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                key: ValueKey(type),
                tween: Tween(begin: animations ? 0.6 : 1, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: TypeOrb(type: type, size: 84, iconSize: 38, selected: true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatPokemonName(type)} type',
                      style: AppTypography.display(
                        26,
                        weight: FontWeight.w700,
                        color: p.foreground,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      typeDescriptions[type] ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: p.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SegmentedPill<MatchupMode>(
                  height: 38,
                  radius: 12,
                  options: const {
                    MatchupMode.attack: 'Attack',
                    MatchupMode.defense: 'Defense',
                  },
                  value: mode,
                  onChanged: onMode,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: p.muted,
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _ViewButton(
                      tooltip: 'Orbit view',
                      icon: Icons.blur_circular,
                      selected: view == _View.orbit,
                      onTap: () => onView(_View.orbit),
                    ),
                    _ViewButton(
                      tooltip: 'List view',
                      icon: Icons.format_list_bulleted,
                      selected: view == _View.list,
                      onTap: () => onView(_View.list),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            attack
                ? 'Damage ${formatPokemonName(type)} moves deal to each type.'
                : 'Damage a ${formatPokemonName(type)} Pokémon takes from each type.',
            style: TextStyle(fontSize: 12.5, color: p.mutedForeground),
          ),
          const SizedBox(height: 14),
          if (relations.hasError && chart == null)
            ErrorView(error: relations.error!)
          else if (chart == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (view == _View.orbit)
            _OrbitSection(
              type: type,
              chart: chart,
              mode: mode,
              focus: focus,
              animations: animations,
              onFocus: onFocus,
              onOpen: onSelect,
            )
          else
            MatchupGroups(chart: chart, mode: mode, onType: onSelect),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? p.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? p.foreground : p.mutedForeground,
          ),
        ),
      ),
    );
  }
}

class _OrbitSection extends StatelessWidget {
  const _OrbitSection({
    required this.type,
    required this.chart,
    required this.mode,
    required this.focus,
    required this.animations,
    required this.onFocus,
    required this.onOpen,
  });

  final String type;
  final Map<String, double> chart;
  final MatchupMode mode;
  final String? focus;
  final bool animations;
  final ValueChanged<String?> onFocus;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final focusType = focus != null && focus != type ? focus : null;
    final m = focusType == null ? null : chart[focusType] ?? 1;

    return Column(
      children: [
        OrbitView(
          selected: type,
          chart: chart,
          mode: mode,
          focus: focusType,
          onFocus: onFocus,
          animations: animations,
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final value in const [2.0, 0.5, 0.0, 1.0])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: relationColor(value, mode),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    legendLabel(value, mode),
                    style: TextStyle(fontSize: 11.5, color: p.mutedForeground),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: focusType == null || m == null
              ? Text(
                  'Tap an outer orb to see the matchup.',
                  style: TextStyle(fontSize: 13, color: p.mutedForeground),
                )
              : Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 44),
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: relationColor(m, mode),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        formatMultiplier(m),
                        style: monoStyle(
                          13,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            matchupSentence(
                              selected: type,
                              other: focusType,
                              multiplier: m,
                              mode: mode,
                            ),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          Text(
                            '${legendLabel(m, mode)} · '
                            '${formatPokemonName(focusType)} type',
                            style: TextStyle(
                              fontSize: 12,
                              color: p.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => onOpen(focusType),
                      child: const Text('Open'),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.selected,
    required this.chart,
    required this.mode,
    required this.onTap,
  });

  final String? selected;
  final Map<String, double>? chart;
  final MatchupMode mode;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 124,
        crossAxisSpacing: 8,
        mainAxisSpacing: 4,
      ),
      itemCount: allPokemonTypes.length,
      itemBuilder: (context, index) {
        final type = allPokemonTypes[index];
        final isSelected = type == selected;
        final m = chart?[type];
        final neutral = m == null || m == 1;
        final dim = selected != null && !isSelected && neutral;
        return Semantics(
          button: true,
          selected: isSelected,
          label: formatPokemonName(type) +
              (m != null && !isSelected ? ', ${formatMultiplier(m)}' : ''),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(type),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: dim ? 0.3 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        scale: isSelected ? 1.08 : 1,
                        child: TypeOrb(
                          type: type,
                          size: 76,
                          iconSize: 32,
                          selected: isSelected,
                        ),
                      ),
                      if (selected != null && !isSelected && !neutral)
                        Positioned(
                          top: -4,
                          right: -8,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 30),
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: relationColor(m, mode),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              formatMultiplier(m),
                              style: monoStyle(
                                11,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    formatPokemonName(type),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
