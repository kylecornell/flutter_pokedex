import 'package:flutter/material.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/pokemon_types.dart';
import '../../../../shared/widgets/chips.dart';
import '../../../../shared/widgets/type_badge.dart';

/// Wrap of selectable type chips (all 18 types).
class TypePicker extends StatelessWidget {
  const TypePicker({super.key, required this.selected, required this.onToggle});

  final List<String> selected;
  final void Function(String type) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in allPokemonTypes)
          PillChip(
            label: formatPokemonName(type),
            selected: selected.contains(type),
            selectedBackground: typeColor(type),
            selectedForeground: typeInk(type),
            dotColor:
                selected.contains(type) ? typeInk(type) : typeColor(type),
            height: 36,
            onTap: () => onToggle(type),
          ),
      ],
    );
  }
}
