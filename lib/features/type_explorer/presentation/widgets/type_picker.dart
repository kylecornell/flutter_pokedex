import 'package:flutter/material.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon_types.dart';
import '../../../../shared/widgets/type_badge.dart';

/// Wrap of selectable type chips.
class TypePicker extends StatelessWidget {
  const TypePicker({super.key, required this.selected, required this.onToggle});

  final List<String> selected;
  final void Function(String type) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final type in allPokemonTypes)
          FilterChip(
            label: Text(formatPokemonName(type)),
            selected: selected.contains(type),
            selectedColor: typeColor(type).withValues(alpha: 0.55),
            onSelected: (_) => onToggle(type),
          ),
      ],
    );
  }
}
