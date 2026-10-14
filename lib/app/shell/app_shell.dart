import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';

/// Frame around the four tabs: keeps each tab's state (scroll position,
/// filters) alive and shows the shared bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: (index) => navigationShell.goBranch(
          index,
          // Tapping the active tab again returns to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
        onCatch: () => context.push('/catch'),
      ),
    );
  }
}
