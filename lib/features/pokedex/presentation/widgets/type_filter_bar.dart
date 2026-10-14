import 'package:flutter/material.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon_types.dart';
import '../../../../shared/widgets/type_badge.dart';

/// Horizontal row of type chips; tapping the selected chip clears it.
class TypeFilterBar extends StatelessWidget {
  const TypeFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final void Function(String? type) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: allPokemonTypes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = allPokemonTypes[index];
          final isSelected = type == selected;
          return FilterChip(
            label: Text(formatPokemonName(type)),
            selected: isSelected,
            selectedColor: typeColor(type).withValues(alpha: 0.55),
            onSelected: (_) => onSelected(isSelected ? null : type),
          );
        },
      ),
    );
  }
}
