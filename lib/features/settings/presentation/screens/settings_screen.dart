import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../../core/utils/text_format.dart';
import '../../../../shared/models/app_settings.dart';
import '../../../../shared/providers/pokemon_providers.dart';
import '../../../../shared/providers/settings_provider.dart';
import '../../../../shared/providers/type_providers.dart';
import '../../../../shared/widgets/chips.dart';
import '../../../../shared/widgets/pokedex_header.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    await ref.read(sharedPreferencesProvider).remove(typeIndexPrefsKey);
    // Best effort and not awaited: emptying the image cache can take a while
    // and may be unavailable on some platforms.
    try {
      unawaited(DefaultCacheManager().emptyCache().catchError((_) {}));
    } catch (_) {}
    // Fresh repositories drop their in-memory caches; the type index reloads.
    ref
      ..invalidate(pokemonRepositoryProvider)
      ..invalidate(typeRepositoryProvider)
      ..invalidate(typeIndexProvider)
      ..invalidate(pokemonIndexProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cached data cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final indexed = ref.watch(typeIndexProvider).value?.length;

    return Material(
      type: MaterialType.transparency,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const PokedexHeader(
            accent: HeaderAccent.blue,
            title: 'Settings',
            subtitle: 'Make the Pokédex yours',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          const _SectionLabel('Appearance'),
          _Card(
            children: [
              _Row(
                title: 'Theme',
                subtitle: 'Follow the system or choose one.',
                trailing: SegmentedPill<ThemeMode>(
                  expand: false,
                  height: 32,
                  options: const {
                    ThemeMode.system: 'Auto',
                    ThemeMode.light: 'Light',
                    ThemeMode.dark: 'Dark',
                  },
                  value: settings.themeMode,
                  onChanged: notifier.setThemeMode,
                ),
              ),
              _Row(
                title: 'Animations',
                subtitle: 'Entrance, floating and stat bar motion.',
                trailing: Switch(
                  value: settings.animationsEnabled,
                  onChanged: notifier.setAnimationsEnabled,
                ),
              ),
              _Row(
                title: 'Card effects',
                subtitle: 'Tilt and holographic light on trading cards.',
                trailing: Switch(
                  value: settings.cardEffects,
                  onChanged: notifier.setCardEffects,
                ),
              ),
              _Row(
                title: 'Grid size',
                subtitle: 'Cards per row in lists.',
                last: true,
                trailing: SegmentedPill<GridDensity>(
                  expand: false,
                  height: 32,
                  options: const {
                    GridDensity.comfortable: 'Large',
                    GridDensity.compact: 'Small',
                  },
                  value: settings.gridDensity,
                  onChanged: notifier.setGridDensity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Viewer'),
          _Card(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Preferred display mode',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'Used when you open a Pokémon.',
                style: TextStyle(fontSize: 12, color: p.mutedForeground),
              ),
              const SizedBox(height: 10),
              SegmentedPill<ViewerMode>(
                options: {for (final m in ViewerMode.values) m: m.label},
                value: settings.viewerMode,
                onChanged: notifier.setViewerMode,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Data'),
          _Card(
            children: [
              _Row(
                title: 'Cached data',
                subtitle: indexed == null
                    ? 'Type index not loaded yet.'
                    : 'Type index for ${formatCount(indexed)} Pokémon.',
                last: true,
                trailing: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.destructive,
                    minimumSize: const Size(70, 40),
                  ),
                  onPressed: () => _clearCache(context, ref),
                  child: const Text('Clear'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionLabel('About'),
          _Card(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Pokédex · version 0.1',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Data from PokéAPI (pokeapi.co). Artwork and sprites from the '
                'PokeAPI sprites repository. 3D models from the community '
                'Pokémon 3D API (non-commercial).',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: p.mutedForeground,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Unofficial fan project. Pokémon and character names are '
                'trademarks of Nintendo, Game Freak and Creatures.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: p.mutedForeground,
                ),
              ),
            ],
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.55,
          color: context.palette.mutedForeground,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.padding = EdgeInsets.zero});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.last = false,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: p.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
