import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/type_providers.dart';
import '../../domain/type_effectiveness_service.dart';

/// What the user picked on the matchup screen.
class MatchupSelection {
  const MatchupSelection({this.attacker, this.defenders = const []});

  final String? attacker;

  /// One or two types (a dual-type Pokémon).
  final List<String> defenders;
}

class MatchupSelectionNotifier extends Notifier<MatchupSelection> {
  @override
  MatchupSelection build() => const MatchupSelection();

  void toggleAttacker(String type) {
    state = MatchupSelection(
      attacker: state.attacker == type ? null : type,
      defenders: state.defenders,
    );
  }

  /// Max two defender types; picking a third drops the oldest.
  void toggleDefender(String type) {
    final defenders = [...state.defenders];
    if (!defenders.remove(type)) {
      if (defenders.length >= 2) defenders.removeAt(0);
      defenders.add(type);
    }
    state = MatchupSelection(attacker: state.attacker, defenders: defenders);
  }

  void clear() => state = const MatchupSelection();
}

final matchupSelectionProvider =
    NotifierProvider<MatchupSelectionNotifier, MatchupSelection>(
  MatchupSelectionNotifier.new,
);

class MatchupResult {
  const MatchupResult({this.attackMultiplier, required this.defenseChart});

  /// Selected attacker vs selected defenders; null when no attacker chosen.
  final double? attackMultiplier;

  /// Every attacking type vs the selected defenders.
  final Map<String, double> defenseChart;
}

/// Null until at least one defender is selected.
final matchupResultProvider = FutureProvider<MatchupResult?>(
  (ref) async {
    final selection = ref.watch(matchupSelectionProvider);
    if (selection.defenders.isEmpty) return null;

    final defenders = await Future.wait(
      selection.defenders.map((t) => ref.watch(pokemonTypeProvider(t).future)),
    );
    final attackerName = selection.attacker;
    final attacker = attackerName == null
        ? null
        : await ref.watch(pokemonTypeProvider(attackerName).future);

    return MatchupResult(
      attackMultiplier: attacker == null
          ? null
          : TypeEffectivenessService.attackMultiplier(
              attacker,
              selection.defenders,
            ),
      defenseChart: TypeEffectivenessService.defenseChart(defenders),
    );
  },
  retry: (_, _) => null,
);
