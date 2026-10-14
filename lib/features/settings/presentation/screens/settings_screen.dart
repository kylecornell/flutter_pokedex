import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/app_settings.dart';
import '../../../../shared/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Theme', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => notifier.setThemeMode(s.first),
          ),
          const SizedBox(height: 24),
          Text('Grid size', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<GridDensity>(
            segments: const [
              ButtonSegment(
                value: GridDensity.compact,
                label: Text('Compact'),
              ),
              ButtonSegment(
                value: GridDensity.comfortable,
                label: Text('Comfortable'),
              ),
            ],
            selected: {settings.gridDensity},
            onSelectionChanged: (s) => notifier.setGridDensity(s.first),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Animations'),
            subtitle: const Text('Page transitions and image fade-in'),
            value: settings.animationsEnabled,
            onChanged: notifier.setAnimationsEnabled,
          ),
        ],
      ),
    );
  }
}
