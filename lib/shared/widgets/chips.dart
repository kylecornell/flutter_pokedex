import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/utils/text_format.dart';
import '../models/pokemon_types.dart';
import 'type_badge.dart';

/// Pill-shaped (or rounded-rect) filter chip from the design.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackground,
    this.selectedForeground,
    this.dotColor,
    this.height = 34,
    this.radius = 999,
    this.fontSize = 12.5,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Defaults to the inverted foreground/background look of "All".
  final Color? selectedBackground;
  final Color? selectedForeground;

  /// Small leading color dot (type chips).
  final Color? dotColor;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = selected ? (selectedBackground ?? p.foreground) : p.card;
    final fg = selected ? (selectedForeground ?? p.background) : p.foreground;
    final border = selected ? (selectedBackground ?? p.foreground) : p.border;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Container(
            height: height,
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal list with soft fades on both edges.
class ChipScroller extends StatelessWidget {
  const ChipScroller({
    super.key,
    required this.children,
    this.height = 34,
    this.spacing = 8,
    this.horizontalPadding = 18,
  });

  final List<Widget> children;
  final double height;
  final double spacing;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final w = rect.width == 0 ? 1.0 : rect.width;
          return LinearGradient(
            colors: const [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0, 16 / w, 1 - 28 / w, 1],
          ).createShader(rect);
        },
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          itemCount: children.length,
          separatorBuilder: (_, _) => SizedBox(width: spacing),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    );
  }
}

/// "All" + one chip per type. Selecting beyond [max] drops the oldest pick
/// (two chips = dual-type filter).
class TypeChipRow extends StatelessWidget {
  const TypeChipRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.types = allPokemonTypes,
    this.max = 2,
    this.height = 34,
    this.fontSize = 12.5,
    this.horizontalPadding = 18,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final List<String> types;
  final int max;
  final double height;
  final double fontSize;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return ChipScroller(
      height: height,
      horizontalPadding: horizontalPadding,
      children: [
        PillChip(
          label: 'All',
          selected: selected.isEmpty,
          height: height,
          fontSize: fontSize,
          onTap: () => onChanged(const []),
        ),
        for (final type in types)
          PillChip(
            label: formatPokemonName(type),
            selected: selected.contains(type),
            selectedBackground: typeColor(type),
            selectedForeground: typeInk(type),
            dotColor: selected.contains(type) ? typeInk(type) : typeColor(type),
            height: height,
            fontSize: fontSize,
            onTap: () {
              var next = selected.contains(type)
                  ? selected.where((t) => t != type).toList()
                  : [...selected, type];
              if (next.length > max) next = next.sublist(next.length - max);
              onChanged(next);
            },
          ),
      ],
    );
  }
}

/// Two or three option segmented control (muted track, card thumb).
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 36,
    this.radius = 10,
    this.expand = true,
  });

  /// Value -> label.
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final double radius;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.muted,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final entry in options.entries)
            Flexible(
              fit: expand ? FlexFit.tight : FlexFit.loose,
              child: Semantics(
                button: true,
                selected: entry.key == value,
                label: entry.value,
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius - 3),
                  onTap: () => onChanged(entry.key),
                  child: Container(
                    height: height,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.key == value ? p.card : Colors.transparent,
                      borderRadius: BorderRadius.circular(radius - 3),
                      boxShadow: entry.key == value
                          ? const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: entry.key == value
                            ? p.foreground
                            : p.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
