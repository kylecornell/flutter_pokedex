/// `mr-mime` -> `Mr Mime`
String formatPokemonName(String apiName) {
  return apiName
      .split('-')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}

/// `25` -> `#0025`
String formatDexNumber(int id) => '#${id.toString().padLeft(4, '0')}';

/// `special-attack` -> `Sp. Atk`, `hp` -> `HP`, `speed` -> `Speed`
String formatStatName(String apiName) => switch (apiName) {
      'hp' => 'HP',
      'special-attack' => 'Sp. Atk',
      'special-defense' => 'Sp. Def',
      _ => formatPokemonName(apiName),
    };

/// `1025` -> `1,025`
String formatCount(int n) => n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
