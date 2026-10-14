import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom navigation from the design: Home, Pokédex, a raised Pokéball
/// "Catch" button in the middle, Favorites, Settings.
///
/// [currentIndex] is the tab branch index (0 home, 1 pokédex, 2 favorites,
/// 3 settings). The Catch button is an action, not a tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onCatch,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCatch;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: Color.alphaBlend(p.card.withValues(alpha: 0.92), p.background),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _NavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  selected: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _NavItem(
                  label: 'Pokédex',
                  icon: Icons.grid_view_outlined,
                  selectedIcon: Icons.grid_view_rounded,
                  selected: currentIndex == 1,
                  onTap: () => onSelect(1),
                ),
                Expanded(child: _CatchButton(onTap: onCatch)),
                _NavItem(
                  label: 'Favorites',
                  icon: Icons.favorite_border,
                  selectedIcon: Icons.favorite,
                  selected: currentIndex == 2,
                  onTap: () => onSelect(2),
                ),
                _NavItem(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  selected: currentIndex == 3,
                  onTap: () => onSelect(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.accentForeground : p.mutedForeground;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? p.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(selected ? selectedIcon : icon, size: 22, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatchButton extends StatelessWidget {
  const _CatchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: 'Catch Pokémon',
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // The ball sits half above the bar.
            Positioned(
              top: -26,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF18181B), width: 3),
                  boxShadow: [
                    BoxShadow(color: p.background, spreadRadius: 4),
                    const BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.44, 0.44, 0.56, 0.56, 1],
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFFEF4444),
                      Color(0xFF18181B),
                      Color(0xFF18181B),
                      Color(0xFFF4F4F5),
                      Color(0xFFF4F4F5),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF18181B), width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 9,
              child: Text(
                'Catch',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.accentForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
