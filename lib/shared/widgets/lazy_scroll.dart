import 'package:flutter/material.dart';

/// Reveals more items as the user nears the bottom of a list.
///
/// Attach [controller] to the scroll view and read [visible] for how many
/// items to render. [onChanged] triggers the rebuild (usually `setState`).
class LazyReveal {
  LazyReveal({
    required this.step,
    required this.onChanged,
  }) : visible = step {
    controller.addListener(_check);
  }

  final int step;
  final VoidCallback onChanged;
  final ScrollController controller = ScrollController();

  int visible;

  /// Set to the current total number of items.
  int total = 0;

  void _check() {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.pixels < position.maxScrollExtent - 400) return;
    if (visible >= total) return;
    visible += step;
    onChanged();
  }

  /// Start again from the first [step] items (after a filter change).
  void reset() => visible = step;

  void dispose() => controller.dispose();
}
