import 'package:go_router/go_router.dart';

import '../../features/type_explorer/presentation/screens/type_detail_screen.dart';
import '../../features/type_explorer/presentation/screens/type_explorer_screen.dart';
import '../../features/type_explorer/presentation/screens/type_matchup_screen.dart';
import '../../features/pokemon_details/presentation/screens/pokemon_detail_screen.dart';
import '../../features/pokedex/presentation/screens/pokedex_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
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
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/types',
      builder: (context, state) => const TypeExplorerScreen(),
    ),
    // Must be declared before '/types/:name' or "matchup" is read as a type.
    GoRoute(
      path: '/types/matchup',
      builder: (context, state) => const TypeMatchupScreen(),
    ),
    GoRoute(
      path: '/types/:name',
      builder: (context, state) =>
          TypeDetailScreen(typeName: state.pathParameters['name']!),
    ),
  ],
);
