import 'package:flutter/material.dart';

import '../../../../shared/widgets/type_badge.dart';
import '../../domain/type_effectiveness_service.dart';

/// Card listing types grouped by multiplier (4x, 2x, 1/2x, ...).
/// Neutral (1x) matchups are left out.
class EffectivenessSection extends StatelessWidget {
  const EffectivenessSection({
    super.key,
    required this.title,
    required this.chart,
    this.onTypeTap,
  });

  final String title;

  /// Type name -> multiplier.
  final Map<String, double> chart;
  final void Function(String type)? onTypeTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final groups = TypeEffectivenessService.groupByMultiplier(chart)
      ..remove(1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            if (groups.isEmpty) const Text('No special matchups.'),
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  multiplierLabel(entry.key),
                  style: textTheme.labelLarge,
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in entry.value)
                    TypeBadge(
                      type: t,
                      onTap: onTypeTap == null ? null : () => onTypeTap!(t),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String multiplierLabel(double m) => switch (m) {
      0 => '0× no effect',
      0.25 => '¼×',
      0.5 => '½×',
      _ => '${m % 1 == 0 ? m.toInt() : m}×',
    };
