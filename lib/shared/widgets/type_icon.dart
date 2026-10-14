import 'package:flutter/material.dart';

/// One recognizable icon per type. Stand-ins for the design's Lucide icons.
const Map<String, IconData> _typeIcons = {
  'normal': Icons.radio_button_checked,
  'fire': Icons.local_fire_department,
  'water': Icons.water_drop,
  'electric': Icons.bolt,
  'grass': Icons.eco,
  'ice': Icons.ac_unit,
  'fighting': Icons.sports_mma,
  'poison': Icons.science,
  'ground': Icons.terrain,
  'flying': Icons.air,
  'psychic': Icons.visibility,
  'bug': Icons.bug_report,
  'rock': Icons.hexagon,
  'ghost': Icons.cloud,
  'dragon': Icons.diamond,
  'dark': Icons.dark_mode,
  'steel': Icons.shield,
  'fairy': Icons.auto_awesome,
};

IconData typeIconData(String type) => _typeIcons[type] ?? Icons.circle;
