import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/text_format.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../shared/providers/type_providers.dart';
import '../../../../shared/widgets/type_badge.dart';
import '../../domain/services/type_effectiveness_service.dart';
import '../widgets/effectiveness_section.dart';

/// Attack and defense matchups of one type.
class TypeDetailScreen extends ConsumerWidget {
  const TypeDetailScreen({super.key, required this.typeName});

  final String typeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ref.watch(pokemonTypeProvider(typeName));

    return Scaffold(
      appBar: AppBar(
        title: Text('${formatPokemonName(typeName)} type'),
        backgroundColor: typeColor(typeName).withValues(alpha: 0.6),
      ),
      body: type.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(pokemonTypeProvider(typeName)),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EffectivenessSection(
              title: 'When attacking',
              chart: TypeEffectivenessService.attackChart(data),
              onTypeTap: (t) => context.push('/types/$t'),
            ),
            const SizedBox(height: 16),
            EffectivenessSection(
              title: 'When defending (damage taken)',
              chart: TypeEffectivenessService.defenseChart([data]),
              onTypeTap: (t) => context.push('/types/$t'),
            ),
          ],
        ),
      ),
    );
  }
}
