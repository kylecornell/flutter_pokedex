import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pokemon_type.dart';
import 'pokemon_providers.dart';

/// Damage relations + members of one type (`fire`).
final pokemonTypeProvider = FutureProvider.family<PokemonType, String>(
  (ref, name) => ref.watch(typeRepositoryProvider).getType(name),
  retry: (_, _) => null,
);
