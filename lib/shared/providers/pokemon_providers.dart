import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../datasources/pokeapi_datasource.dart';
import '../repositories/pokemon_repository.dart';
import '../repositories/type_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.close);
  return client;
});

final pokeApiDataSourceProvider = Provider<PokeApiDataSource>(
  (ref) => PokeApiDataSource(ref.watch(apiClientProvider)),
);

final pokemonRepositoryProvider = Provider<PokemonRepository>(
  (ref) => PokemonRepository(ref.watch(pokeApiDataSourceProvider)),
);

final typeRepositoryProvider = Provider<TypeRepository>(
  (ref) => TypeRepository(ref.watch(pokeApiDataSourceProvider)),
);
