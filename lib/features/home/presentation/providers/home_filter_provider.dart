import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the Home tab is currently searching/filtering for.
class HomeFilter {
  const HomeFilter({this.query = '', this.types = const []});

  final String query;

  /// Up to two types (dual-type filter).
  final List<String> types;
}

class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => const HomeFilter();

  void setQuery(String query) =>
      state = HomeFilter(query: query.trim(), types: state.types);

  void setTypes(List<String> types) =>
      state = HomeFilter(query: state.query, types: types);
}

final homeFilterProvider =
    NotifierProvider<HomeFilterNotifier, HomeFilter>(HomeFilterNotifier.new);
