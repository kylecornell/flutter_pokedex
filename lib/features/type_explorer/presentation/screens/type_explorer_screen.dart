import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/models/pokemon_types.dart';
import '../widgets/type_orb.dart';

/// Grid of the 18 types. Needs no network: the list of types is fixed.
class TypeExplorerScreen extends StatelessWidget {
  const TypeExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Type Explorer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/types/matchup'),
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Matchup calculator'),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: allPokemonTypes.length,
              itemBuilder: (context, index) {
                final type = allPokemonTypes[index];
                return TypeOrb(
                  type: type,
                  onTap: () => context.push('/types/$type'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
