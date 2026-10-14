import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/text_format.dart';
import '../../../../../shared/models/move_info.dart';
import '../../../../../shared/models/pokemon.dart';
import '../../../../../shared/models/pokemon_types.dart';
import '../../../../../shared/providers/pokemon_providers.dart';
import '../../../../../shared/widgets/chips.dart';
import '../../../../../shared/widgets/type_badge.dart';

const _methodLabels = {
  'level-up': 'Level up',
  'machine': 'TM',
  'egg': 'Egg',
  'tutor': 'Tutor',
};

/// The learnset of the newest game, filterable by method and move type.
/// Move details (type, power, ...) are fetched six at a time, then cached.
class MovesTab extends ConsumerStatefulWidget {
  const MovesTab({
    super.key,
    required this.moves,
    required this.versionGroupName,
  });

  final List<LearnedMove> moves;
  final String versionGroupName;

  @override
  ConsumerState<MovesTab> createState() => _MovesTabState();
}

class _MovesTabState extends ConsumerState<MovesTab> {
  final Map<String, MoveInfo?> _info = {};
  String _method = 'all';
  String? _type;

  List<String> get _names =>
      {for (final m in widget.moves) m.name}.toList(growable: false);

  @override
  void initState() {
    super.initState();
    _prefetch();
  }

  Future<void> _prefetch() async {
    final repo = ref.read(pokemonRepositoryProvider);
    final queue = [..._names];
    var next = 0;

    Future<void> worker() async {
      while (mounted && next < queue.length) {
        final name = queue[next++];
        MoveInfo? info;
        try {
          info = await repo.getMove(name);
        } catch (_) {
          info = null; // keep the row, show "…" for its details
        }
        if (!mounted) return;
        setState(() => _info[name] = info);
      }
    }

    await Future.wait(List.generate(6, (_) => worker()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final methods = {for (final m in widget.moves) m.method}.toList();
    final total = _names.length;
    final loaded = _info.length;

    final typesPresent = [
      for (final t in allPokemonTypes)
        if (_info.values.any((i) => i?.type == t)) t,
    ];

    final rows = widget.moves.where((m) {
      if (_method != 'all' && m.method != _method) return false;
      if (_type != null && _info[m.name]?.type != _type) return false;
      return true;
    }).toList();

    final game = formatPokemonName(widget.versionGroupName)
        .replaceFirst(' ', ' / ');
    final note = 'Learnset from $game ($total moves). Moves differ between '
        'games.${loaded < total ? ' Loading move details $loaded/$total…' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          note,
          style: TextStyle(fontSize: 12, height: 1.45, color: p.mutedForeground),
        ),
        const SizedBox(height: 10),
        ChipScroller(
          height: 32,
          spacing: 6,
          horizontalPadding: 0,
          children: [
            PillChip(
              label: 'All',
              selected: _method == 'all',
              height: 32,
              radius: 9,
              fontSize: 12,
              onTap: () => setState(() => _method = 'all'),
            ),
            for (final m in methods)
              PillChip(
                label: _methodLabels[m] ?? formatPokemonName(m),
                selected: _method == m,
                height: 32,
                radius: 9,
                fontSize: 12,
                onTap: () => setState(() => _method = m),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TypeChipRow(
          selected: [?_type],
          types: typesPresent,
          max: 1,
          height: 30,
          fontSize: 11.5,
          horizontalPadding: 0,
          onChanged: (t) => setState(() => _type = t.isEmpty ? null : t.last),
        ),
        const SizedBox(height: 4),
        for (final move in rows) _MoveRow(move: move, info: _info[move.name]),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No moves match these filters.',
              style: TextStyle(color: p.mutedForeground),
            ),
          ),
      ],
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.move, required this.info});

  final LearnedMove move;
  final MoveInfo? info;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final how = move.method == 'level-up'
        ? (move.level > 0 ? 'Lv ${move.level}' : 'Evo')
        : (_methodLabels[move.method] ?? formatPokemonName(move.method));
    String num(int? v) => v?.toString() ?? '—';

    final type = info?.type;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatPokemonName(move.name),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: type == null ? p.muted : typeColor(type),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type == null ? '…' : formatPokemonName(type),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: type == null ? p.mutedForeground : typeInk(type),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              color: p.mutedForeground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            child: Row(
              children: [
                Text(
                  how,
                  style: TextStyle(
                    color: p.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Text('Pwr ${num(info?.power)}'),
                const SizedBox(width: 10),
                Text('Acc ${num(info?.accuracy)}'),
                const SizedBox(width: 10),
                Text('PP ${num(info?.pp)}'),
                const Spacer(),
                Text(
                  info == null || info!.damageClass.isEmpty
                      ? ''
                      : formatPokemonName(info!.damageClass),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
