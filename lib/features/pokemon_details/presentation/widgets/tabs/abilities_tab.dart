import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/text_format.dart';
import '../../../../../shared/models/pokemon.dart';
import '../../providers/pokemon_detail_provider.dart';

class AbilitiesTab extends ConsumerWidget {
  const AbilitiesTab({super.key, required this.abilities});

  final List<PokemonAbility> abilities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    if (abilities.isEmpty) {
      return Text(
        'No abilities listed.',
        style: TextStyle(color: p.mutedForeground),
      );
    }
    return Column(
      children: [
        for (final ability in abilities)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatPokemonName(ability.name),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (ability.isHidden)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.muted,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: p.border),
                          ),
                          child: const Text(
                            'Hidden',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ref
                            .watch(abilityDescriptionProvider(ability.name))
                            .when(
                              data: (d) => d,
                              loading: () => 'Loading description…',
                              error: (_, _) => 'Description unavailable.',
                            ),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: p.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
