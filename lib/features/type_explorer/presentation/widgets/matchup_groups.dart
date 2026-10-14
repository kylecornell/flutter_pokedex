import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../shared/widgets/type_orb.dart';
import '../../domain/type_explorer_logic.dart';

/// List view of the explorer: one card per multiplier group, with the
/// matching types as labeled orbs.
class MatchupGroups extends StatelessWidget {
  const MatchupGroups({
    super.key,
    required this.chart,
    required this.mode,
    required this.onType,
  });

  final Map<String, double> chart;
  final MatchupMode mode;
  final ValueChanged<String> onType;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const multipliers = [2.0, 0.5, 0.0, 1.0];

    return Column(
      children: [
        for (final m in multipliers) ...[
          Builder(
            builder: (context) {
              final types = [
                for (final e in chart.entries)
                  if (e.value == m) e.key,
              ];
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          constraints: const BoxConstraints(minWidth: 38),
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: relationColor(m, mode),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            formatMultiplier(m),
                            style: monoStyle(
                              12,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          groupTitle(m, mode),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          types.length == 1 ? '1 type' : '${types.length} types',
                          style: TextStyle(fontSize: 12, color: p.mutedForeground),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (types.isEmpty)
                      Text(
                        'None',
                        style: TextStyle(fontSize: 13, color: p.mutedForeground),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 12,
                        children: [
                          for (final t in types)
                            Semantics(
                              button: true,
                              label: formatPokemonName(t),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => onType(t),
                                child: SizedBox(
                                  width: 56,
                                  child: Column(
                                    children: [
                                      TypeOrb(type: t, size: 42, iconSize: 19),
                                      const SizedBox(height: 5),
                                      Text(
                                        formatPokemonName(t),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
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
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
