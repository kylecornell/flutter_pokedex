import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../core/utils/text_format.dart';
import '../../../../../shared/models/pokemon.dart';
import '../../../../../shared/providers/settings_provider.dart';

/// Bars are scaled to this value (the practical ceiling of base stats).
const statBarScale = 180;

class StatsTab extends ConsumerStatefulWidget {
  const StatsTab({super.key, required this.stats, required this.color});

  final List<PokemonStat> stats;
  final Color color;

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab> {
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    final animate = ref.read(settingsProvider).animationsEnabled;
    if (!animate) {
      _filled = true;
    } else {
      Future<void>.delayed(const Duration(milliseconds: 50), () {
        if (mounted) setState(() => _filled = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final animate = ref.watch(settingsProvider.select((s) => s.animationsEnabled));
    final total = widget.stats.fold<int>(0, (sum, s) => sum + s.value);

    return Column(
      children: [
        for (final (i, stat) in widget.stats.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  child: Text(
                    formatStatName(stat.name),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: p.mutedForeground,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${stat.value}',
                    textAlign: TextAlign.right,
                    style: monoStyle(14, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.muted,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        end: _filled
                            ? (stat.value / statBarScale).clamp(0.0, 1.0)
                            : 0.0,
                      ),
                      duration: animate
                          ? Duration(milliseconds: 900 + i * 60)
                          : Duration.zero,
                      curve: const Cubic(0.16, 1, 0.3, 1),
                      builder: (context, value, _) => FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 62,
                child: Text(
                  'Total',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$total',
                  textAlign: TextAlign.right,
                  style: monoStyle(14, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Bars scaled to $statBarScale',
                style: TextStyle(fontSize: 12, color: p.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
