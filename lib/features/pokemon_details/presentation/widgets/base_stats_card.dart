import 'package:flutter/material.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon.dart';

/// Highest possible base stat; bars are scaled against it.
const _maxBaseStat = 255;

class BaseStatsCard extends StatelessWidget {
  const BaseStatsCard({super.key, required this.stats});

  final List<PokemonStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final total = stats.fold<int>(0, (sum, s) => sum + s.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Base stats', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final stat in stats) _StatRow(stat: stat),
            const Divider(),
            _StatRow(
              stat: PokemonStat(name: 'total', value: total),
              showBar: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stat, this.showBar = true});

  final PokemonStat stat;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = (stat.value / _maxBaseStat).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(formatStatName(stat.name))),
          SizedBox(
            width: 40,
            child: Text(
              '${stat.value}',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: showBar
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      color: fraction > 0.5 ? scheme.primary : scheme.tertiary,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
