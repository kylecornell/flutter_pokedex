import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/utils/text_format.dart';
import '../models/pokemon_summary.dart';
import '../providers/type_providers.dart';
import 'favorite_button.dart';
import 'pokeball_outline.dart';
import 'pokemon_artwork.dart';
import 'type_badge.dart';

/// Grid card: type-tinted background, number, name, type pills, artwork.
class PokemonCard extends ConsumerWidget {
  const PokemonCard({super.key, required this.pokemon, this.onTap});

  static const double height = 158;

  final PokemonSummary pokemon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final index = ref.watch(typeIndexProvider);
    final types = index.value?[pokemon.id];
    final pending = index.isLoading;

    final c1 = types != null && types.isNotEmpty
        ? typeColor(types.first)
        : p.mutedForeground;
    final c2 = types != null && types.length > 1 ? typeColor(types[1]) : c1;
    final tinted = types != null && types.isNotEmpty;

    return Semantics(
      button: true,
      label: '${formatPokemonName(pokemon.name)}, ${formatDexNumber(pokemon.id)}',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          gradient: tinted
              ? LinearGradient(
                  begin: const Alignment(-0.6, -1),
                  end: const Alignment(0.6, 1),
                  colors: [
                    Color.lerp(p.card, c1, 0.26)!,
                    Color.lerp(p.card, c2, 0.09)!,
                  ],
                )
              : null,
          color: tinted ? null : p.card,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned(
                  right: -28,
                  bottom: -28,
                  child: PokeballOutline(
                    size: 124,
                    color: c1.withValues(alpha: 0.16),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 2,
                  width: 92,
                  height: 92,
                  child: PokemonArtwork(url: pokemon.artworkUrl),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              formatDexNumber(pokemon.id),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: monoStyle(11, color: p.mutedForeground),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(9, -9),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: FavoriteButton(
                                pokemonId: pokemon.id,
                                compact: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Transform.translate(
                        offset: const Offset(0, -9),
                        child: Text(
                          formatPokemonName(pokemon.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: p.foreground,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (types != null)
                              for (final t in types)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _TypePill(type: t),
                                ),
                            if (types == null && pending)
                              Container(
                                width: 48,
                                height: 17,
                                decoration: BoxDecoration(
                                  color: p.border,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: typeColor(type),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatPokemonName(type),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: typeInk(type),
        ),
      ),
    );
  }
}
