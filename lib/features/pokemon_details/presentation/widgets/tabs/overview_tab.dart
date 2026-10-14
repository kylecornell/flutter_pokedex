import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/card_view_model.dart';

/// Flavor text and a grid of key facts.
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, required this.data});

  final CardViewModel data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.flavor,
          style: const TextStyle(fontSize: 14.5, height: 1.55),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: p.border,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final half = (c.maxWidth - 1) / 2;
                return Wrap(
                  spacing: 1,
                  runSpacing: 1,
                  children: [
                    for (final (k, v) in data.facts)
                      Container(
                        width: half,
                        color: p.card,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: p.mutedForeground,
                              ),
                            ),
                            Text(
                              v,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
