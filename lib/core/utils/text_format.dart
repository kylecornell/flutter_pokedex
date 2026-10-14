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
