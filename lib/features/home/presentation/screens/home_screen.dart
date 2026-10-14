import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pokédex')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome, Trainer!'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/pokedex'),
              icon: const Icon(Icons.catching_pokemon),
              label: const Text('Open Pokédex'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/types'),
              icon: const Icon(Icons.bubble_chart),
              label: const Text('Type Explorer'),
            ),
          ],
        ),
      ),
    );
  }
}
