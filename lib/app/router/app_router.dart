import 'package:go_router/go_router.dart';

import '../../features/pokemon_details/presentation/screens/pokemon_detail_screen.dart';
import '../../features/pokedex/presentation/screens/pokedex_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

/// Central route table. Add new screens here.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/pokedex',
      builder: (context, state) => const PokedexScreen(),
    ),
    GoRoute(
      path: '/pokemon/:id',
      builder: (context, state) =>
          PokemonDetailScreen(pokemonId: state.pathParameters['id']!),
    ),
  ],
);
