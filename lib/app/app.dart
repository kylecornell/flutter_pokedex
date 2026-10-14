import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/providers/settings_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget: wires theme, settings and navigation together.
class PokedexApp extends ConsumerWidget {
  const PokedexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final animations =
        ref.watch(settingsProvider.select((s) => s.animationsEnabled));

    return MaterialApp.router(
      title: 'Pokédex',
      theme: AppTheme.light(animations: animations),
      darkTheme: AppTheme.dark(animations: animations),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
