import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/shared_preferences_provider.dart';
import '../models/pokemon_type.dart';
import 'pokemon_providers.dart';

/// Damage relations + members of one type (`fire`).
final pokemonTypeProvider = FutureProvider.family<PokemonType, String>(
  (ref, name) => ref.watch(typeRepositoryProvider).getType(name),
  retry: (_, _) => null,
);

/// SharedPreferences key of the cached type index.
const typeIndexPrefsKey = 'pdx_type_index';

/// Fewer entries than this means the cache is incomplete and is refetched.
const _minCachedEntries = 900;

/// National Dex number -> types (`{25: [electric]}`).
///
/// Built from the 18 `/type/{name}` calls once, then stored on the device so
/// later launches skip the network. Powers type badges on cards and
/// multi-type filtering.
final typeIndexProvider = FutureProvider<Map<int, List<String>>>(
  (ref) async {
    final prefs = ref.watch(sharedPreferencesProvider);

    final cached = prefs.getString(typeIndexPrefsKey);
    if (cached != null) {
      try {
        final decoded = (jsonDecode(cached) as Map<String, dynamic>).map(
          (k, v) => MapEntry(int.parse(k), (v as List<dynamic>).cast<String>()),
        );
        if (decoded.length >= _minCachedEntries) return decoded;
      } catch (_) {
        // Corrupt cache: fall through and rebuild it.
      }
    }

    final index = await ref.watch(typeRepositoryProvider).getTypeIndex();
    await prefs.setString(
      typeIndexPrefsKey,
      jsonEncode(index.map((k, v) => MapEntry('$k', v))),
    );
    return index;
  },
  retry: (_, _) => null,
);
