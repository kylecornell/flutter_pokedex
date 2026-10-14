import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../providers/matchup_provider.dart';
import '../../../../shared/widgets/pokedex_header.dart';
import '../widgets/effectiveness_section.dart';
import '../widgets/type_picker.dart';

/// Pick an attacker type and one or two defender types (a dual-type
/// Pokémon) to see the damage multiplier and the full defense chart.
class TypeMatchupScreen extends ConsumerWidget {
  const TypeMatchupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(matchupSelectionProvider);
    final notifier = ref.read(matchupSelectionProvider.notifier);
    final result = ref.watch(matchupResultProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          PokedexHeader(
            accent: HeaderAccent.yellow,
            title: 'Type Matchup',
            subtitle: 'Attacker vs one or two defender types',
            onBack: () => context.canPop() ? context.pop() : context.go('/'),
            actions: [
              HeaderIconButton(
                accent: HeaderAccent.yellow,
                tooltip: 'Clear',
                icon: Icons.restart_alt,
                onPressed: notifier.clear,
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Attacker', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          TypePicker(
            selected: [if (selection.attacker != null) selection.attacker!],
            onToggle: notifier.toggleAttacker,
          ),
          const SizedBox(height: 20),
          Text('Defender (pick 1 or 2 types)', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          TypePicker(
            selected: selection.defenders,
            onToggle: notifier.toggleDefender,
          ),
          const SizedBox(height: 20),
          if (selection.defenders.isEmpty)
            const Text('Select a defender type to see matchups.')
          else
            result.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(matchupResultProvider),
              ),
              data: (data) {
                if (data == null) return const SizedBox.shrink();
                final defenderLabel =
                    selection.defenders.map(formatPokemonName).join('/');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.attackMultiplier != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                multiplierLabel(data.attackMultiplier!),
                                style: textTheme.displayMedium,
                              ),
                              Text(
                                '${formatPokemonName(selection.attacker!)} '
                                'attacking $defenderLabel',
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    EffectivenessSection(
                      title: 'Damage taken by $defenderLabel',
                      chart: data.defenseChart,
                    ),
                  ],
                );
              },
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
