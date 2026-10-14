import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget: wires theme and navigation together.
class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pokédex',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
